import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // --- DUMMY DATA NOTIFIKASI ---
  // Tipe: 'transaction', 'promo', 'system'
  List<Map<String, dynamic>> _notifications = [
    {
      "id": 1,
      "title": "Pembayaran Berhasil!",
      "message": "Booking lapangan Futsal A untuk tgl 30 Des telah lunas. Tunjukkan QR Code saat datang.",
      "time": "Baru saja",
      "type": "transaction",
      "isRead": false,
    },
    {
      "id": 2,
      "title": "Jangan Lupa Bayar!",
      "message": "Booking #BK-009 akan hangus dalam 15 menit. Segera selesaikan pembayaran.",
      "time": "10 Menit yang lalu",
      "type": "transaction",
      "isRead": false,
    },
    {
      "id": 3,
      "title": "Promo Tahun Baru 🎉",
      "message": "Dapatkan diskon 50% untuk booking di malam tahun baru. Gunakan kode: NEWYEAR50.",
      "time": "1 Jam yang lalu",
      "type": "promo",
      "isRead": true,
    },
    {
      "id": 4,
      "title": "Maintenance Sistem",
      "message": "Aplikasi Sporta akan mengalami maintenance pada jam 02:00 - 04:00 WIB.",
      "time": "Kemarin",
      "type": "system",
      "isRead": true,
    },
    {
      "id": 5,
      "title": "Refund Berhasil",
      "message": "Dana sebesar Rp 150.000 telah dikembalikan ke saldo SportaPay Anda.",
      "time": "2 Hari yang lalu",
      "type": "transaction",
      "isRead": true,
    },
  ];

  // Fungsi: Menandai semua jadi "Read"
  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Semua notifikasi ditandai sudah dibaca")),
    );
  }

  // Fungsi: Menghapus notifikasi (Swipe)
  void _deleteNotification(int id) {
    setState(() {
      // Cari notifikasi asli di list utama dan hapus
      // (Di real app, ini panggil API delete)
      _notifications.removeWhere((element) => element['id'] == id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notifikasi dihapus"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tab: Transaksi & Info
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Notifikasi", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Tombol Mark All Read
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                "Tandai Dibaca", 
                style: TextStyle(
                  color: Color(0xFF0047FF), 
                  fontWeight: FontWeight.bold
                )
              ),
            )
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF0047FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF0047FF),
            tabs: [
              Tab(text: "Transaksi"),
              Tab(text: "Info & Promo"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList("transaction"), // Tab 1
            _buildNotificationList("other"),       // Tab 2 (Promo + System)
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(String filter) {
    // Filter data sesuai tab
    List<Map<String, dynamic>> filteredList;
    if (filter == "transaction") {
      filteredList = _notifications.where((n) => n['type'] == 'transaction').toList();
    } else {
      filteredList = _notifications.where((n) => n['type'] != 'transaction').toList();
    }

    // EMPTY STATE (Kalau kosong)
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Belum ada notifikasi", 
              style: TextStyle(color: Colors.grey[500])
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return _buildNotificationItem(item);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    // Tentukan Icon & Warna berdasarkan tipe
    IconData icon;
    Color color;
    switch (item['type']) {
      case 'transaction':
        icon = Icons.receipt_long;
        color = Colors.green;
        break;
      case 'promo':
        icon = Icons.local_offer;
        color = Colors.orange;
        break;
      case 'system':
        icon = Icons.info;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    bool isUnread = !item['isRead'];

    return Dismissible(
      key: Key(item['id'].toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Hapus item dari list (Simulasi)
        // Di real case, panggil API delete dulu
        _deleteNotification(item['id']);
      },
      child: GestureDetector(
        onTap: () {
          // Saat diklik, tandai sudah dibaca
          setState(() {
            // Cari item asli di list utama dan update
            var originalItem = _notifications.firstWhere((element) => element['id'] == item['id']);
            originalItem['isRead'] = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF0F5FF) : Colors.white, // Kalau unread warnanya biru muda banget
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: isUnread ? [] : [ // Kalau unread gak usah shadow biar flat
              BoxShadow(
                color: Colors.black.withOpacity(0.03), 
                blurRadius: 10, 
                offset: const Offset(0, 4)
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon Bulat
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              
              const SizedBox(width: 16),
              
              // 2. Konten Teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'], 
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold, 
                              fontSize: 14,
                              color: Colors.black87
                            )
                          ),
                        ),
                        
                        // Titik Merah kalau Unread
                        if (isUnread)
                          Container(
                            width: 8, 
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red, 
                              shape: BoxShape.circle
                            ),
                          )
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      item['message'], 
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[600], 
                        height: 1.5
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      item['time'], 
                      style: TextStyle(
                        fontSize: 10, 
                        color: Colors.grey[400], 
                        fontWeight: FontWeight.w500
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}