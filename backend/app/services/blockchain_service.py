import os
import json
import logging
from typing import Dict, Any, Tuple
from web3 import Web3
from eth_account import Account
from app.core.config import settings

logger = logging.getLogger("thalia_backend")

class BlockchainService:
    """
    Web3.py bridge to Hardhat Local Node for THALIARegistry Smart Contract.
    Creates immutable audit trails of disaster alert triggers.
    """
    _w3 = None
    _contract = None
    _account = None

    @classmethod
    def get_w3(cls) -> Web3:
        if cls._w3 is None:
            cls._w3 = Web3(Web3.HTTPProvider(settings.HARDHAT_RPC_URL))
        return cls._w3

    @classmethod
    def _init_contract(cls):
        w3 = cls.get_w3()
        if not w3.is_connected():
            logger.warning(f"Hardhat local node is not reachable at {settings.HARDHAT_RPC_URL}. Blockchain recording will run in fallback simulation mode.")
            return False

        # Load contract info
        contract_info_path = os.path.join(os.path.dirname(__file__), "../core/contract_info.json")
        if not os.path.exists(contract_info_path):
            logger.warning("contract_info.json not found. Run hardhat deploy first.")
            return False

        try:
            with open(contract_info_path, "r") as f:
                info = json.load(f)
            
            address = Web3.to_checksum_address(info["address"])
            cls._contract = w3.eth.contract(address=address, abi=info["abi"])
            cls._account = Account.from_key(settings.BLOCKCHAIN_PRIVATE_KEY)
            return True
        except Exception as e:
            logger.error(f"Failed to load smart contract: {e}")
            return False

    @classmethod
    def compute_data_hash(cls, telemetry_data: Dict[str, Any]) -> str:
        """
        Calculates SHA-3 / Keccak256 hash of the telemetry snapshot
        to guarantee tamper-proof audit verification.
        """
        canonical_str = json.dumps(telemetry_data, sort_keys=True)
        keccak_hash = Web3.keccak(text=canonical_str)
        return keccak_hash.hex()

    @classmethod
    def record_alert_on_chain(
        cls,
        data_hash_hex: str,
        location: str,
        habitat_summary: str,
        severity: str
    ) -> Dict[str, Any]:
        """
        Records the alert event onto Hardhat node smart contract.
        Severity: 1 for Alert/Waspada, 2 for Danger/Bahaya
        """
        w3 = cls.get_w3()
        severity_code = 2 if severity.lower() == "danger" else 1

        # Check if contract is initialized
        if cls._contract is None:
            if not cls._init_contract():
                return {
                    "status": "SIMULATED",
                    "data_hash": data_hash_hex,
                    "tx_hash": "0x" + "a" * 64,
                    "event_id": 1,
                    "block_number": 1,
                    "note": "Hardhat node offline; hash computed cryptographically"
                }

        try:
            sender = cls._account.address
            nonce = w3.eth.get_transaction_count(sender)

            # bytes32 representation
            hash_bytes = bytes.fromhex(data_hash_hex[2:] if data_hash_hex.startswith("0x") else data_hash_hex)

            fn = cls._contract.functions.logAlert(
                hash_bytes,
                location,
                habitat_summary[:100],
                severity_code
            )
            gas_est = fn.estimate_gas({'from': sender})
            tx_data = fn.build_transaction({
                'from': sender,
                'nonce': nonce,
                'gas': int(gas_est * 1.3) + 20000,
                'gasPrice': w3.eth.gas_price
            })

            signed_tx = w3.eth.account.sign_transaction(tx_data, private_key=settings.BLOCKCHAIN_PRIVATE_KEY)
            raw = getattr(signed_tx, "raw_transaction", None) or getattr(signed_tx, "rawTransaction")
            tx_hash = w3.eth.send_raw_transaction(raw)
            
            # Wait for receipt on local Hardhat
            receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=10)
            if receipt.status != 1:
                raise RuntimeError("Transaction reverted on-chain")
            
            total_alerts = cls._contract.functions.totalAlerts().call()

            logger.info(f"Alert recorded on blockchain successfully! Tx: {tx_hash.hex()} Event ID: {total_alerts}")

            return {
                "status": "CONFIRMED",
                "data_hash": data_hash_hex,
                "tx_hash": "0x" + tx_hash.hex().removeprefix("0x"),
                "event_id": total_alerts,
                "block_number": receipt.blockNumber,
                "gas_used": receipt.gasUsed
            }
        except Exception as e:
            logger.error(f"Error executing blockchain transaction: {e}")
            return {
                "status": "FAILED",
                "data_hash": data_hash_hex,
                "tx_hash": None,
                "event_id": None,
                "error": str(e)
            }

    @classmethod
    def get_status(cls) -> Dict[str, Any]:
        """Health info of the blockchain layer for the dashboard."""
        info = {
            "node_connected": False,
            "rpc_url": settings.HARDHAT_RPC_URL,
            "contract_deployed": False,
            "contract_address": None,
            "block_number": None,
            "total_alerts_on_chain": None,
        }
        try:
            w3 = cls.get_w3()
            if not w3.is_connected():
                return info
            info["node_connected"] = True
            info["block_number"] = w3.eth.block_number
            if cls._contract is None:
                cls._init_contract()
            if cls._contract is not None:
                code = w3.eth.get_code(cls._contract.address)
                if code and len(code) > 0:
                    info["contract_deployed"] = True
                    info["contract_address"] = cls._contract.address
                    info["total_alerts_on_chain"] = cls._contract.functions.totalAlerts().call()
                else:
                    # Stale contract_info.json (node was restarted) -> force reload next time
                    cls._contract = None
        except Exception as e:
            logger.error(f"Blockchain status check failed: {e}")
        return info

    @classmethod
    def verify_on_chain(cls, event_id: int, data_hash_hex: str) -> bool:
        """
        Queries smart contract to verify if the given hash matches the on-chain record.
        Returns False if Hardhat node is offline or contract is not deployed.
        """
        w3 = cls.get_w3()
        if not w3.is_connected():
            cls._contract = None
            return False

        if cls._contract is None and not cls._init_contract():
            return False

        try:
            code = w3.eth.get_code(cls._contract.address)
            if not code or len(code) == 0:
                cls._contract = None
                return False
            hash_bytes = bytes.fromhex(data_hash_hex[2:] if data_hash_hex.startswith("0x") else data_hash_hex)
            return bool(cls._contract.functions.verifyHash(event_id, hash_bytes).call())
        except Exception as e:
            logger.error(f"Verification query failed: {e}")
            return False
