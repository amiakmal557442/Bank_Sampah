import 'package:flutter/material.dart';
import 'db_helper.dart';

// ============================================================================
// Halaman Kelola Akun & Role — Admin Dashboard (Desktop/Web)
// FR-AD-03 — Mengelola akun pengguna, petugas, dan staf beserta role &
//             permission masing-masing.
// FR-SH-05 — Autentikasi multi-role dengan hak akses berbeda setiap peran.
//
// Backend: DatabaseHelper.instance (SQLite native / in-memory web)
//   • getAllUsers()          → load daftar akun
//   • registerUser()         → tambah akun baru
//   • updateUserProfile()    → edit nama/email/hp/role
//   • toggleUserStatus()     → aktif / nonaktif
//   • deleteUser()           → hapus permanen
//   • getStafPermissions()   → baca permission matrix Staf Kantor
//   • saveStafPermissions()  → simpan perubahan permission
// ============================================================================

const Color primaryGreen = Color(0xFF268B07);
const Color limeGreen = Color(0xFF32CD32);
const Color pageBackground = Color(0xFFF5F6F8);
const Color darkText = Color(0xFF0F172A);
const Color subtleText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);
const Color borderColor = Color(0xFFE2E8F0);
const Color secondaryDarkText = Color(0xFF334155);

// ---------------------------------------------------------------------------
// Permission module definitions (ordered list displayed in matrix)
// ---------------------------------------------------------------------------

final List<Map<String, dynamic>> kPermissionModules = [
  {'key': 'Overview', 'icon': Icons.dashboard_rounded},
  {'key': 'Master Data', 'icon': Icons.storage_rounded},
  {'key': 'Manajemen Transaksi', 'icon': Icons.receipt_long_rounded},
  {'key': 'Operasional Lapangan', 'icon': Icons.local_shipping_rounded},
  {'key': 'Laporan & Analitik', 'icon': Icons.bar_chart_rounded},
  {'key': 'Konfigurasi Sistem', 'icon': Icons.settings_rounded},
  {'key': 'Kelola Akun & Role', 'icon': Icons.people_rounded},
  {'key': 'Audit Log', 'icon': Icons.shield_rounded},
];

// ---------------------------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------------------------

class KelolaAkunRoleScreen extends StatefulWidget {
  const KelolaAkunRoleScreen({super.key});

  @override
  State<KelolaAkunRoleScreen> createState() => _KelolaAkunRoleScreenState();
}

class _KelolaAkunRoleScreenState extends State<KelolaAkunRoleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Tab 1: Daftar Akun ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _allAccounts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterRole; // null = Semua
  final TextEditingController _searchController = TextEditingController();

  // ── Tab 2: Role & Permission ─────────────────────────────────────────────
  Map<String, bool> _permissions = {};
  bool _permissionsLoading = true;
  bool _permissionsDirty = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAccounts();
    _loadPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── DATA LOADING ─────────────────────────────────────────────────────────

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllUsers();
      if (mounted) {
        setState(() {
          _allAccounts = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPermissions() async {
    setState(() => _permissionsLoading = true);
    try {
      final perms = await DatabaseHelper.instance.getStafPermissions();
      if (mounted) {
        setState(() {
          _permissions = perms;
          _permissionsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _permissionsLoading = false);
    }
  }

  Future<void> _savePermissions() async {
    final ok = await DatabaseHelper.instance.saveStafPermissions(_permissions);
    if (mounted) {
      _showSnackBar(
        ok ? 'Permission berhasil disimpan' : 'Gagal menyimpan permission',
        ok,
      );
      if (ok) setState(() => _permissionsDirty = false);
    }
  }

  // ── FILTERED LIST ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredAccounts {
    return _allAccounts.where((acc) {
      final matchRole = _filterRole == null || acc['role'] == _filterRole;
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          (acc['full_name'] ?? '').toLowerCase().contains(q) ||
          (acc['email'] ?? '').toLowerCase().contains(q);
      return matchRole && matchSearch;
    }).toList();
  }

  // ── ROLE HELPERS ──────────────────────────────────────────────────────────

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'staf_kantor':
        return 'Staf Kantor';
      case 'petugas':
        return 'Petugas Lapangan';
      default:
        return 'End User';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return primaryGreen;
      case 'staf_kantor':
        return const Color(0xFF5F8A4A);
      case 'petugas':
        return const Color(0xFF64748B);
      default:
        return mutedText;
    }
  }

  String _platformLabel(String role) {
    switch (role) {
      case 'admin':
      case 'staf_kantor':
        return 'Web';
      case 'petugas':
        return 'Mobile (app terpisah)';
      default:
        return 'Mobile';
    }
  }

  // ── SNACKBAR ──────────────────────────────────────────────────────────────

  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'PlusJakartaSans'),
        ),
        backgroundColor: success ? primaryGreen : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── DIALOGS ───────────────────────────────────────────────────────────────

  void _showAddAccountDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'nasabah';
    bool obscurePass = true;
    bool isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tambah Akun Baru',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: darkText,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    'Nama Lengkap',
                    nameCtrl,
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    'Email',
                    emailCtrl,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    'No. HP (opsional)',
                    phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    'Password',
                    passCtrl,
                    icon: Icons.lock_outline_rounded,
                    obscure: obscurePass,
                    suffix: IconButton(
                      icon: Icon(
                        obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: subtleText,
                      ),
                      onPressed: () => setD(() => obscurePass = !obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogDropdown(
                    label: 'Role',
                    icon: Icons.badge_outlined,
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrator'),
                      ),
                      DropdownMenuItem(
                        value: 'staf_kantor',
                        child: Text('Staf Kantor'),
                      ),
                      DropdownMenuItem(
                        value: 'petugas',
                        child: Text('Petugas Lapangan'),
                      ),
                      DropdownMenuItem(
                        value: 'nasabah',
                        child: Text('End User (Nasabah)'),
                      ),
                    ],
                    onChanged: (v) => setD(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: subtleText,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text(
                'Simpan',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => isSubmitting = true);

                      final id =
                          'user-${DateTime.now().millisecondsSinceEpoch}';
                      final userData = {
                        'id': id,
                        'full_name': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim().toLowerCase(),
                        'phone_number': phoneCtrl.text.trim(),
                        'password': passCtrl.text,
                        'role': selectedRole,
                        'address': '',
                        'default_setor_method': 'drop_in',
                        'point_balance': 0,
                        'is_active': 1,
                      };

                      final ok = await DatabaseHelper.instance.registerUser(
                        userData,
                      );
                      if (mounted) {
                        Navigator.pop(ctx);
                        _showSnackBar(
                          ok
                              ? 'Akun "${nameCtrl.text.trim()}" berhasil dibuat'
                              : 'Email atau No. HP sudah terdaftar',
                          ok,
                        );
                        if (ok) _loadAccounts();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(Map<String, dynamic> acc) {
    final nameCtrl = TextEditingController(text: acc['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: acc['email'] ?? '');
    final phoneCtrl = TextEditingController(text: acc['phone_number'] ?? '');
    String selectedRole = acc['role'] ?? 'nasabah';
    bool isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F8A4A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF5F8A4A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Edit Akun — ${acc['full_name'] ?? ''}',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    'Nama Lengkap',
                    nameCtrl,
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    'Email',
                    emailCtrl,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    'No. HP',
                    phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _dialogDropdown(
                    label: 'Role',
                    icon: Icons.badge_outlined,
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrator'),
                      ),
                      DropdownMenuItem(
                        value: 'staf_kantor',
                        child: Text('Staf Kantor'),
                      ),
                      DropdownMenuItem(
                        value: 'petugas',
                        child: Text('Petugas Lapangan'),
                      ),
                      DropdownMenuItem(
                        value: 'nasabah',
                        child: Text('End User (Nasabah)'),
                      ),
                    ],
                    onChanged: (v) => setD(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: subtleText,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F8A4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: const Text(
                'Perbarui',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => isSubmitting = true);

                      final ok = await DatabaseHelper.instance
                          .updateUserProfile(acc['id'], {
                            'full_name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim().toLowerCase(),
                            'phone_number': phoneCtrl.text.trim(),
                            'role': selectedRole,
                          });

                      if (mounted) {
                        Navigator.pop(ctx);
                        _showSnackBar(
                          ok
                              ? 'Akun berhasil diperbarui'
                              : 'Gagal memperbarui akun',
                          ok,
                        );
                        if (ok) _loadAccounts();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetPasswordDialog(Map<String, dynamic> acc) async {
    final passCtrl = TextEditingController();
    bool obscure = true;
    bool isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: darkText,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akun: ${acc['full_name'] ?? '-'}',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12.5,
                      color: subtleText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    'Password Baru',
                    passCtrl,
                    icon: Icons.lock_outline_rounded,
                    obscure: obscure,
                    suffix: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: subtleText,
                      ),
                      onPressed: () => setD(() => obscure = !obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: subtleText,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => isSubmitting = true);

                      final ok = await DatabaseHelper.instance
                          .updateUserProfile(acc['id'], {
                            'password': passCtrl.text,
                          });

                      if (mounted) {
                        Navigator.pop(ctx);
                        _showSnackBar(
                          ok
                              ? 'Password berhasil direset'
                              : 'Gagal mereset password',
                          ok,
                        );
                      }
                    },
              child: const Text(
                'Reset',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> acc) async {
    final isActive = (acc['is_active'] ?? 1) == 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isActive ? 'Nonaktifkan Akun?' : 'Aktifkan Akun?',
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: darkText,
          ),
        ),
        content: Text(
          '${acc['full_name']} akan ${isActive ? 'dinonaktifkan dan tidak bisa login' : 'diaktifkan kembali'}.',
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13.5,
            color: subtleText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: subtleText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.orange.shade700 : primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isActive ? 'Nonaktifkan' : 'Aktifkan',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await DatabaseHelper.instance.toggleUserStatus(
        acc['id'],
        !isActive,
      );
      _showSnackBar(
        ok ? 'Status akun berhasil diubah' : 'Gagal mengubah status akun',
        ok,
      );
      if (ok) _loadAccounts();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> acc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Hapus Akun?',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: darkText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun berikut akan dihapus secara permanen:',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: subtleText,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F8E8),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (acc['full_name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acc['full_name'] ?? '-',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: darkText,
                          ),
                        ),
                        Text(
                          acc['email'] ?? '-',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11.5,
                            color: subtleText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '⚠️ Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: subtleText,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text(
              'Ya, Hapus',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await DatabaseHelper.instance.deleteUser(acc['id']);
      _showSnackBar(ok ? 'Akun berhasil dihapus' : 'Gagal menghapus akun', ok);
      if (ok) _loadAccounts();
    }
  }

  // ── DIALOG WIDGET HELPERS ─────────────────────────────────────────────────

  Widget _dialogField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13,
        color: darkText,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: mutedText)
            : null,
        labelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          color: subtleText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        suffixIcon: suffix,
        isDense: true,
      ),
    );
  }

  Widget _dialogDropdown({
    required String label,
    IconData? icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13,
        color: darkText,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: mutedText)
            : null,
        labelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          color: subtleText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildDaftarAkunTab(), _buildRolePermissionTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Akun & Role',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'FR-AD-03 · FR-SH-05 — kelola akun & atur permission tiap role',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: subtleText,
                ),
              ),
            ],
          ),
          // Tombol berubah sesuai tab aktif
          AnimatedBuilder(
            animation: _tabController,
            builder: (_, __) {
              if (_tabController.index == 0) {
                return ElevatedButton.icon(
                  onPressed: _showAddAccountDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah Akun'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              // Tab permission
              if (_permissionsDirty) {
                return ElevatedButton.icon(
                  onPressed: _savePermissions,
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Simpan Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: primaryGreen,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Permission tersimpan',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryGreen,
          unselectedLabelColor: mutedText,
          indicatorColor: primaryGreen,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          onTap: (_) => setState(() {}),
          tabs: [
            Tab(
              text:
                  'Daftar Akun${_allAccounts.isNotEmpty ? ' (${_allAccounts.length})' : ''}',
            ),
            const Tab(text: 'Role & Permission'),
          ],
        ),
      ),
    );
  }

  // ── SHARED CARD CONTAINER ─────────────────────────────────────────────────

  Widget _cardContainer({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(28, 16, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── TAB 1: DAFTAR AKUN ───────────────────────────────────────────────────

  Widget _roleFilterChip(String label, String? role) {
    final isSelected = _filterRole == role;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = role),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : secondaryDarkText,
          ),
        ),
      ),
    );
  }

  Widget _buildDaftarAkunTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    final filtered = _filteredAccounts;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips + Search bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _roleFilterChip('Semua', null),
                        _roleFilterChip('Administrator', 'admin'),
                        _roleFilterChip('Staf Kantor', 'staf_kantor'),
                        _roleFilterChip('Petugas', 'petugas'),
                        _roleFilterChip('End User', 'nasabah'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 230,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email...',
                      hintStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: mutedText,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 17,
                        color: mutedText,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: mutedText,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryGreen,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Empty state ────────────────────────────────────────────────
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.manage_accounts_rounded,
                      size: 52,
                      color: mutedText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada akun yang cocok dengan pencarian'
                          : 'Belum ada akun dalam kategori ini',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        color: mutedText,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _cardContainer(
              child: Column(
                children: [
                  // Table header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 0.5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('Nama', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Email', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Role', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Platform', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('Status', style: _headerStyle),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Aksi', style: _headerStyle),
                        ),
                      ],
                    ),
                  ),
                  // Data rows
                  ...filtered.map((acc) => _buildAccountRow(acc)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountRow(Map<String, dynamic> acc) {
    final isActive = (acc['is_active'] ?? 1) == 1;
    final role = (acc['role'] ?? 'nasabah') as String;
    final name = (acc['full_name'] ?? '-') as String;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.transparent : Colors.grey.shade50,
        border: const Border(
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // ── Nama ─────────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F8E8)
                        : const Color(0xFFF1F1F1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? primaryGreen : mutedText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isActive ? darkText : mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // ── Email ─────────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Text(
              (acc['email'] ?? '-') as String,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: subtleText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ── Role badge ────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(role),
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _roleColor(role),
                ),
              ),
            ),
          ),
          // ── Platform ─────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              _platformLabel(role),
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: mutedText,
              ),
            ),
          ),
          // ── Status badge ─────────────────────────────────────────────
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE8F8E8)
                    : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? primaryGreen : mutedText,
                ),
              ),
            ),
          ),
          // ── Action buttons ────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _iconBtn(
                  Icons.edit_outlined,
                  tooltip: 'Edit akun',
                  onTap: () => _showEditAccountDialog(acc),
                ),
                const SizedBox(width: 5),
                _iconBtn(
                  Icons.lock_reset_rounded,
                  tooltip: 'Reset password',
                  color: Colors.orange.shade600,
                  onTap: () => _showResetPasswordDialog(acc),
                ),
                const SizedBox(width: 5),
                _iconBtn(
                  isActive
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                  tooltip: isActive ? 'Nonaktifkan' : 'Aktifkan',
                  color: isActive
                      ? Colors.orange.shade700
                      : const Color(0xFF5F8A4A),
                  onTap: () => _toggleUserStatus(acc),
                ),
                const SizedBox(width: 5),
                _iconBtn(
                  Icons.delete_outline_rounded,
                  tooltip: 'Hapus akun',
                  color: Colors.red.shade400,
                  onTap: () => _deleteUser(acc),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData icon, {
    required VoidCallback onTap,
    String? tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: pageBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Icon(icon, size: 15, color: color ?? subtleText),
        ),
      ),
    );
  }

  // ── TAB 2: ROLE & PERMISSION MATRIX ──────────────────────────────────────

  Widget _buildRolePermissionTab() {
    if (_permissionsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: limeGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: limeGreen.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_rounded,
                  color: limeGreen.withValues(alpha: 0.85),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Matriks ini mengatur hak akses Staf Kantor di dashboard web. '
                    'Admin selalu memiliki akses penuh (terkunci). '
                    'Petugas Lapangan bekerja lewat aplikasi mobile terpisah.',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F8A4A),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _cardContainer(
            child: Column(
              children: [
                // Matrix header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 4,
                        child: Text('Modul / Fitur', style: _headerStyle),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Column(
                            children: [
                              const Text('Admin', style: _headerStyle),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'terkunci',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Center(
                          child: Text('Staf Kantor', style: _headerStyle),
                        ),
                      ),
                    ],
                  ),
                ),

                // Module permission rows
                ...kPermissionModules.map((mod) {
                  final key = mod['key'] as String;
                  final icon = mod['icon'] as IconData;
                  final hasAccess = _permissions[key] ?? false;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Module name + icon
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: pageBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  size: 15,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                key,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Admin: always checked, locked
                        const Expanded(
                          flex: 1,
                          child: Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                        // Staf Kantor: togglable
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _permissions[key] = !hasAccess;
                                _permissionsDirty = true;
                              }),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  hasAccess
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_outlined,
                                  key: ValueKey(hasAccess),
                                  size: 20,
                                  color: hasAccess ? primaryGreen : mutedText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Footer note
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 13,
                        color: mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Klik ikon di kolom Staf Kantor untuk mengubah akses, lalu tekan "Simpan Permission".',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          color: mutedText,
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// SHARED TEXT STYLE
// ---------------------------------------------------------------------------

const TextStyle _headerStyle = TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: subtleText,
  letterSpacing: 0.3,
);
