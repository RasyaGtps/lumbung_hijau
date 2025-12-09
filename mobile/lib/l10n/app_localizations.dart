class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(String languageCode) {
    return AppLocalizations(languageCode);
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      // Auth
      'welcome': 'Selamat Datang',
      'login': 'Masuk',
      'register': 'Daftar',
      'logout': 'Keluar',
      'email': 'Email',
      'password': 'Kata Sandi',
      'forgot_password': 'Lupa Kata Sandi?',
      'dont_have_account': 'Belum memiliki Akun?',
      'create': 'Buat',
      
      // Dashboard
      'waste_bank': 'Bank Sampah',
      'your_points': 'Total Poin Anda',
      'points': 'Poin',
      'exchange': 'Tukar',
      'total_waste': 'Total Sampah',
      'trees_planted': 'Pohon Ditanam',
      'services': 'Layanan',
      'deposit_waste': 'Setor Sampah',
      'deposit_waste_desc': 'Tukar sampah jadi poin',
      'other_menu': 'Menu Lainnya',
      'history': 'Riwayat',
      'rewards': 'Hadiah',
      'location': 'Lokasi',
      'education': 'Edukasi',
      'ranking': 'Ranking',
      'settings': 'Pengaturan',
      
      // Settings
      'edit_profile': 'Edit Profil',
      'edit_profile_desc': 'Ubah nama dan foto profil',
      'change_password': 'Ubah Password',
      'change_password_desc': 'Ganti password akun Anda',
      'phone_number': 'Nomor Telepon',
      'phone_number_desc': 'Kelola nomor telepon',
      'notifications': 'Notifikasi',
      'notifications_desc': 'Atur preferensi notifikasi',
      'language': 'Bahasa',
      'theme': 'Tema',
      'light': 'Terang',
      'dark': 'Gelap',
      'help': 'Bantuan',
      'help_desc': 'FAQ dan dukungan',
      'about_app': 'Tentang Aplikasi',
      'version': 'Versi 1.0.0',
      'privacy_policy': 'Kebijakan Privasi',
      'privacy_policy_desc': 'Baca kebijakan privasi kami',
      
      // Dialog
      'logout_title': 'Keluar Akun',
      'logout_message': 'Apakah Anda yakin ingin keluar dari akun Anda?',
      'cancel': 'Batal',
      'confirm': 'Ya',
    },
    'en': {
      // Auth
      'welcome': 'Welcome',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'create': 'Create',
      
      // Dashboard
      'waste_bank': 'Waste Bank',
      'your_points': 'Your Total Points',
      'points': 'Points',
      'exchange': 'Exchange',
      'total_waste': 'Total Waste',
      'trees_planted': 'Trees Planted',
      'services': 'Services',
      'deposit_waste': 'Deposit Waste',
      'deposit_waste_desc': 'Exchange waste for points',
      'other_menu': 'Other Menu',
      'history': 'History',
      'rewards': 'Rewards',
      'location': 'Location',
      'education': 'Education',
      'ranking': 'Ranking',
      'settings': 'Settings',
      
      // Settings
      'edit_profile': 'Edit Profile',
      'edit_profile_desc': 'Change name and profile photo',
      'change_password': 'Change Password',
      'change_password_desc': 'Change your account password',
      'phone_number': 'Phone Number',
      'phone_number_desc': 'Manage phone number',
      'notifications': 'Notifications',
      'notifications_desc': 'Set notification preferences',
      'language': 'Language',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'help': 'Help',
      'help_desc': 'FAQ and support',
      'about_app': 'About App',
      'version': 'Version 1.0.0',
      'privacy_policy': 'Privacy Policy',
      'privacy_policy_desc': 'Read our privacy policy',
      
      // Dialog
      'logout_title': 'Logout Account',
      'logout_message': 'Are you sure you want to logout from your account?',
      'cancel': 'Cancel',
      'confirm': 'Yes',
    },
  };

  String translate(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}
