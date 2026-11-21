import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/auth_models.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/tactile_interaction.dart';
import 'security_screen.dart';

/// Layar 6 pada login_ui.figcraft: "Profil Saya"
/// menghubungkan tombol "Pengaturan (Tema & Versi)" langsung ke halaman Pengaturan awal.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.dashboardController,
    required this.authController,
    required this.climate,
  });

  final DashboardController dashboardController;
  final AuthController authController;
  final ClimatePalette climate;

  Future<void> _openEditProfileSheet(
    BuildContext context, {
    required String currentName,
    required String currentHandle,
    required String currentPhone,
  }) async {
    final nameCtrl = TextEditingController(text: currentName);
    final handleCtrl = TextEditingController(text: currentHandle);
    final phoneCtrl = TextEditingController(text: currentPhone == '-' ? '' : currentPhone);
    String? errorMsg;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: climate.cardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                18,
                22,
                22 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: climate.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: handleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengguna (Handle)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMsg!,
                      style: const TextStyle(
                        color: Color(0xFFB33A22),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          setModalState(() => errorMsg = 'Nama lengkap wajib diisi.');
                          return;
                        }
                        try {
                          await authController.updateActiveProfile(
                            fullName: nameCtrl.text.trim(),
                            handle: handleCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty
                                ? '-'
                                : phoneCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } catch (_) {
                          setModalState(() => errorMsg = 'Gagal menyimpan perubahan profil.');
                        }
                      },
                      child: const Text('Simpan Perubahan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameCtrl.dispose();
    handleCtrl.dispose();
    phoneCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = authController.activeSession;
    final photoBytes =
        authController.profilePhotoBytes ?? authController.registerModel.profileImageBytes;
    final displayName = (session?.userName ?? '').trim().isNotEmpty
        ? session!.userName!
        : 'Petugas T.H.A.L.I.A';
    final displayEmail = (session?.email ?? '').trim().isNotEmpty
        ? session!.email!
        : 'petugas@thalia.id';
    final displayHandle = (session?.handle ?? '').trim().isNotEmpty
        ? session!.handle!
        : '@petugas_thalia';
    final displayPhone = (session?.phone ?? '').trim().isNotEmpty
        ? session!.phone!
        : '-';
    final displayLocation = authController.gpsModel.resolvedAddress;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubpageWaveHeader(
            climate: climate,
            eyebrowText: 'Akun Pengguna & Wilayah',
            titleText: 'Profil Saya',
            onTapBack: dashboardController.closeProfile,
            onTapProfile: dashboardController.closeProfile,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
            child: Column(
              children: [
                // 1. Kartu Header Avatar & Edit Profil
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: climate.cardFill,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: climate.border),
                  ),
                  child: Row(
                    children: [
                      TactilePressable(
                        onTap: authController.pickProfilePhotoFromGallery,
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: climate.primaryBrand,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: photoBytes != null
                                    ? Image.memory(
                                        photoBytes,
                                        cacheWidth: 180,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.person_rounded,
                                        size: 38,
                                        color: climate.warmDot,
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: climate.activeForecastBg,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: climate.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: climate.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TactilePressable(
                              onTap: () => _openEditProfileSheet(
                                context,
                                currentName: displayName,
                                currentHandle: displayHandle,
                                currentPhone: displayPhone,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: climate.pillFill,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: climate.primaryBrand,
                                  ),
                                ),
                                child: Text(
                                  'Edit Profil',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: climate.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Kartu Tabel Detail Pengguna & Daerah Pantauan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: climate.cardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: climate.border),
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                        label: 'Nama Pengguna',
                        value: displayHandle,
                        climate: climate,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: climate.border, height: 1),
                      ),
                      _ProfileInfoRow(
                        label: 'Nomor Telepon',
                        value: displayPhone,
                        climate: climate,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: climate.border, height: 1),
                      ),
                      _ProfileInfoRow(
                        label: 'Daerah Pantauan',
                        value: displayLocation,
                        valueColor: climate.primaryBrand,
                        climate: climate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Tombol Menu Pengaturan (Masuk ke Halaman Pengaturan Awal)
                _ProfileActionTile(
                  label: 'Pengaturan (Tema & Versi)',
                  leadingIcon: Icons.settings_outlined,
                  isHighlighted: true,
                  climate: climate,
                  onTap: () =>
                      authController.navigateTo(AuthScreenStep.settings),
                ),
                const SizedBox(height: 8),

                _ProfileActionTile(
                  label: 'Ubah Daerah & Lokasi Cuaca',
                  climate: climate,
                  onTap: () => dashboardController.selectTab(DashboardTab.maps),
                ),
                const SizedBox(height: 8),

                _ProfileActionTile(
                  label: 'Keamanan Akun & Kata Sandi',
                  climate: climate,
                  onTap: () => SecurityScreen.open(
                    context,
                    dashboardController: dashboardController,
                    authController: authController,
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Tombol Keluar Akun (Log Out)
                TactilePressable(
                  onTap: () {
                    dashboardController.closeProfile();
                    authController.logout();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: climate.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: climate.primaryBrand,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Keluar Akun (Log Out)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: climate.primaryBrand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.climate,
    this.valueColor,
  });

  final String label;
  final String value;
  final ClimatePalette climate;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: climate.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor ?? climate.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.label,
    required this.climate,
    required this.onTap,
    this.leadingIcon,
    this.isHighlighted = false,
  });

  final String label;
  final ClimatePalette climate;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: climate.cardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted ? climate.primaryBrand : climate.border,
            width: isHighlighted ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 18,
                color: climate.primaryBrand,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: climate.primaryDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: climate.primaryBrand,
            ),
          ],
        ),
      ),
    );
  }
}
