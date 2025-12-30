import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/colors.dart';
import 'venue_detail_page.dart';

class MyBookingPage extends StatefulWidget {
  final bool showBackButton;
  
  const MyBookingPage({super.key, this.showBackButton = false});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- DUMMY DATA ---
  final List<Map<String, dynamic>> _allBookings = [
    {
      "id": "BK-001",
      "venue": "Sporta Futsal Center",
      "field": "Lapangan A (Vinyl)",
      "date": "30 Des 2025",
      "time": "18:00 - 20:00",
      "price": 300000, // Harga Asli (int)
      "status": "pending",
      "countdown": "00:15:00"
    },
    {
      "id": "BK-002",
      "venue": "Gor Badminton Juara",
      "field": "Court 1",
      "date": "31 Des 2025",
      "time": "10:00 - 11:00",
      "price": 80000,
      "status": "active",
    },
    {
      "id": "BK-003",
      "venue": "Tennis Court Senayan",
      "field": "Outdoor 2",
      "date": "25 Des 2025",
      "time": "16:00 - 18:00",
      "price": 250000,
      "status": "completed",
    },
    {
      "id": "BK-004",
      "venue": "Kolam Renang Segar",
      "field": "Tiket Masuk",
      "date": "20 Des 2025",
      "time": "08:00 - 12:00",
      "price": 50000,
      "status": "cancelled",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Pesanan Saya", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ) : null,
        automaticallyImplyLeading: widget.showBackButton,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0047FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0047FF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Menunggu"),
            Tab(text: "Aktif"),
            Tab(text: "Riwayat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList("pending"),
          _buildBookingList("active"),
          _buildBookingList("history"),
        ],
      ),
    );
  }

  Widget _buildBookingList(String filterStatus) {
    List<Map<String, dynamic>> filteredData;
    
    if (filterStatus == "history") {
      filteredData = _allBookings.where((item) => 
        item['status'] == 'cancelled' || item['status'] == 'completed'
      ).toList();
    } else {
      filteredData = _allBookings.where((item) => 
        item['status'] == filterStatus
      ).toList();
    }

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Belum ada booking di sini", 
              style: TextStyle(color: Colors.grey[500])
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Colors.grey.shade200, thickness: 1),
      ),
      itemBuilder: (context, index) {
        return BookingCard(data: filteredData[index]);
      },
    );
  }
}

// =========================================================
// 1. WIDGET KARTU BOOKING (DESAIN BARU + INTEGRASI SELECTOR)
// =========================================================
class BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const BookingCard({super.key, required this.data});

  // --- LOGIC NAVIGASI ---
  // A. Langsung ke halaman pembayaran dengan metode default (QRIS)
  void _goToPaymentDirect(BuildContext context) {
    Map<String, dynamic> paymentData = {
      ...data,
      "selectedMethod": "QRIS (Gopay/OVO/Dana)",
      "adminFee": 700,
      "totalWithFee": data['price'] + 700,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWaitingPage(bookingData: paymentData),
      ),
    );
  }

  // B. Panggil Bottom Sheet Pilih Pembayaran (untuk ganti metode)
  void _goToPaymentSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: PaymentSelectorSheet(totalPrice: data['price']),
      ),
    ).then((result) {
      // Jika user memilih metode (result tidak null)
      if (result != null) {
        // Gabungkan data booking lama dengan data pembayaran baru
        Map<String, dynamic> paymentData = {
          ...data,
          "selectedMethod": result['method'],
          "adminFee": result['fee'],
          "totalWithFee": result['total'],
        };

        // Lanjut ke halaman instruksi bayar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWaitingPage(bookingData: paymentData),
          ),
        );
      }
    });
  }

  void _goToTicket(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => TicketDetailPage(bookingData: data))
    );
  }

  void _rebook(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VenueDetailPage()),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context, 
      builder: (context) => RatingDialog(venueName: data['venue'])
    );
  }

  @override
  Widget build(BuildContext context) {
    String status = data['status'];
    Color themeColor;
    String statusText;
    String mainBtnText;
    Color btnColor;
    IconData statusIcon;
    VoidCallback? onMainAction;
    bool showSecondaryBtn = false;

    // --- CONFIG UI BERDASARKAN STATUS ---
    switch (status) {
      case 'pending':
        themeColor = Colors.orange;
        statusText = "Menunggu Pembayaran";
        mainBtnText = "BAYAR SEKARANG";
        btnColor = AppColors.primaryBlue;
        statusIcon = Icons.timer_outlined;
        onMainAction = () => _goToPaymentDirect(context); // Langsung ke halaman bayar
        showSecondaryBtn = true;
        break;
      case 'active':
        themeColor = AppColors.primaryBlue;
        statusText = "Booking Confirmed";
        mainBtnText = "LIHAT E-TICKET";
        btnColor = AppColors.primaryBlue;
        statusIcon = Icons.verified;
        onMainAction = () => _goToTicket(context);
        break;
      case 'cancelled':
        themeColor = Colors.red;
        statusText = "Dibatalkan";
        mainBtnText = "BOOKING LAGI";
        btnColor = AppColors.primaryBlue;
        statusIcon = Icons.cancel_outlined;
        onMainAction = () => _rebook(context);
        break;
      case 'completed':
        themeColor = Colors.green;
        statusText = "Selesai";
        mainBtnText = "BERI RATING";
        btnColor = AppColors.primaryBlue;
        statusIcon = Icons.thumb_up_alt_outlined;
        onMainAction = () => _showRatingDialog(context);
        break;
      default:
        themeColor = Colors.grey;
        statusText = "Unknown";
        mainBtnText = "DETAIL";
        btnColor = AppColors.primaryBlue;
        statusIcon = Icons.help_outline;
        onMainAction = () {};
    }

    // --- HELPER FORMAT CURRENCY ---
    String formatCurrency(int amount) {
      return "Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
        (Match m) => '${m[1]}.'
      )}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), 
            spreadRadius: 1, 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1), 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 18, color: themeColor),
                    const SizedBox(width: 8),
                    Text(
                      statusText, 
                      style: TextStyle(
                        color: themeColor, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 13
                      )
                    ),
                  ],
                ),
                if (status == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.av_timer, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          data['countdown'] ?? "00:00", 
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.red
                          )
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // BODY
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64, 
                  width: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[100], 
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Icon(Icons.sports_soccer, color: Colors.grey[400]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['venue'], 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16, 
                          color: Colors.black87
                        ), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['field'], 
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            data['date'], 
                            style: TextStyle(
                              color: Colors.grey[600], 
                              fontSize: 12, 
                              fontWeight: FontWeight.w500
                            )
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            data['time'], 
                            style: TextStyle(
                              color: Colors.grey[600], 
                              fontSize: 12, 
                              fontWeight: FontWeight.w500
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100, thickness: 1),

          // FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Harga", 
                          style: TextStyle(fontSize: 11, color: Colors.grey)
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(data['price']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.black
                          )
                        ),
                      ],
                    ),
                    if (status == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code, size: 14, color: Colors.cyan),
                            SizedBox(width: 4),
                            Text(
                              "QRIS", 
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.cyan
                              )
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (showSecondaryBtn) ...[
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => _goToPaymentSelector(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Ganti", 
                            style: TextStyle(fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onMainAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          mainBtnText, 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 2. PAYMENT SELECTOR SHEET (MENU PILIH METODE BAYAR)
// =========================================================
class PaymentSelectorSheet extends StatelessWidget {
  final int totalPrice;

  const PaymentSelectorSheet({super.key, required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    // Helper format currency
    String formatCurrency(int amount) {
      return "Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
        (Match m) => '${m[1]}.'
      )}";
    }

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Sheet
          Container(
            width: 40, 
            height: 4, 
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300], 
              borderRadius: BorderRadius.circular(10)
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Pilih Pembayaran",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
          ),
          const Divider(height: 1),

          // Ringkasan Tagihan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFF8F9FA),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(color: Colors.grey)),
                Text(
                  formatCurrency(totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black
                  )
                ),
              ],
            ),
          ),

          // List Metode
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildSectionTitle("Rekomendasi"),
                _buildPaymentOption(
                  context, 
                  icon: Icons.qr_code_scanner, 
                  title: "QRIS (Gopay/OVO/Dana)", 
                  fee: 700, 
                  color: Colors.blue, 
                  isRecommended: true
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Virtual Account"),
                _buildPaymentOption(
                  context, 
                  icon: Icons.account_balance, 
                  title: "BCA Virtual Account", 
                  fee: 2500, 
                  color: Colors.purple
                ),
                _buildPaymentOption(
                  context, 
                  icon: Icons.account_balance, 
                  title: "Mandiri Virtual Account", 
                  fee: 2500, 
                  color: Colors.blue[900]!
                ),
                _buildPaymentOption(
                  context, 
                  icon: Icons.account_balance, 
                  title: "BRI Virtual Account", 
                  fee: 2500, 
                  color: Colors.orange
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Gerai Retail"),
                _buildPaymentOption(
                  context, 
                  icon: Icons.storefront, 
                  title: "Alfamart / Indomaret", 
                  fee: 5000, 
                  color: Colors.red
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title, 
        style: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey
        )
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, {
    required IconData icon, 
    required String title, 
    required int fee, 
    required Color color, 
    bool isRecommended = false
  }) {
    int finalPrice = totalPrice + fee;
    
    // Helper format di dalam list
    String formatCurrency(int amount) => "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    )}";

    return InkWell(
      onTap: () {
        // Balikkan data pilihan
        Navigator.pop(context, {
          "method": title, 
          "fee": fee, 
          "total": finalPrice
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? const Color(0xFF0047FF) : Colors.grey.shade200
          ),
          boxShadow: [
            if(isRecommended) 
              BoxShadow(
                color: const Color(0xFF0047FF).withOpacity(0.1), 
                blurRadius: 8, 
                offset: const Offset(0, 4)
              )
          ]
        ),
        child: Row(
          children: [
            Container(
              height: 50, 
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title, 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14
                          ), 
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                      if(isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0047FF), 
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: const Text(
                            "PROMO", 
                            style: TextStyle(
                              fontSize: 8, 
                              color: Colors.white, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fee == 0 ? "Bebas Biaya Admin" : "Biaya Admin: ${formatCurrency(fee)}",
                    style: TextStyle(
                      fontSize: 12, 
                      color: fee == 0 ? Colors.green : Colors.grey[600]
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 3. PAYMENT WAITING PAGE (INSTRUKSI BAYAR)
// =========================================================
class PaymentWaitingPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const PaymentWaitingPage({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    // Ambil data yang dikirim dari Selector Sheet
    String method = bookingData['selectedMethod'] ?? "Metode Pembayaran";
    int subtotal = bookingData['price'] ?? 0;
    int adminFee = bookingData['adminFee'] ?? 0;
    int total = bookingData['totalWithFee'] ?? subtotal;

    String formatCurrency(int amount) => "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Selesaikan Pembayaran",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Countdown Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timer_outlined, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selesaikan pembayaran dalam",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookingData['countdown'] ?? "00:15:00",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Booking Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Booking",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow("Venue", bookingData['venue'] ?? "-"),
                  _buildDetailRow("Lapangan", bookingData['field'] ?? "-"),
                  _buildDetailRow("Tanggal", bookingData['date'] ?? "-"),
                  _buildDetailRow("Waktu", bookingData['time'] ?? "-"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metode Pembayaran Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Metode Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          method.contains("QRIS") ? Icons.qr_code_scanner : Icons.account_balance,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Nomor VA / Kode Bayar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          method.contains("QRIS") ? "Scan QR Code" : "Nomor Virtual Account",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "8800 1234 5678 9012",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Nomor disalin!")),
                                );
                              },
                              child: Icon(Icons.copy, size: 18, color: AppColors.primaryBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rincian Pembayaran Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rincian Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow("Subtotal", formatCurrency(subtotal)),
                  const SizedBox(height: 8),
                  _buildPriceRow("Biaya Admin", formatCurrency(adminFee)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pembayaran",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        formatCurrency(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Button Konfirmasi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mengecek Pembayaran...")),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Saya Sudah Bayar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon warning
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade400,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Title
                            const Text(
                              "Batalkan Pesanan?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              "Apakah kamu yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      "Kembali",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // tutup dialog
                                      Navigator.pop(context); // kembali ke halaman sebelumnya
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                                              SizedBox(width: 12),
                                              Text("Pesanan berhasil dibatalkan"),
                                            ],
                                          ),
                                          backgroundColor: Colors.red.shade400,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Ya, Batalkan",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Batalkan Pesanan",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// =========================================================
// 4. HALAMAN TIKET & RATING
// =========================================================
class TicketDetailPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const TicketDetailPage({super.key, required this.bookingData});

  void _shareTicket() {
    final String shareText = '''
🎫 E-Ticket Sporta

📍 ${bookingData['venue']}
🏟️ ${bookingData['field']}
📅 ${bookingData['date']}
⏰ ${bookingData['time']}

Kode Booking: ${bookingData['id']}

Tunjukkan e-ticket ini saat datang ke venue.
''';

    Share.share(shareText, subject: 'E-Ticket Sporta - ${bookingData['venue']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "E-Ticket",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _shareTicket,
            icon: const Icon(Icons.share, color: AppColors.primaryBlue),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ticket Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header section with gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue,
                          AppColors.primaryBlue.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Confirmed",
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bookingData['venue'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookingData['field'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashed divider
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: List.generate(
                                (constraints.maxWidth / 10).floor(),
                                (index) => Container(
                                  width: 5,
                                  height: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                  color: Colors.grey[300],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // QR Code section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Date & Time
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  icon: Icons.calendar_today_outlined,
                                  label: "Tanggal",
                                  value: bookingData['date'],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  icon: Icons.schedule,
                                  label: "Waktu",
                                  value: bookingData['time'],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 160,
                                width: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.qr_code_2,
                                    size: 140,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Scan QR untuk verifikasi",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Booking Code
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Kode Booking",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bookingData['id'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 2,
                                  color: AppColors.primaryBlue,
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
            ),
            const SizedBox(height: 16),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Tunjukkan e-ticket ini ke petugas saat datang ke venue",
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _shareTicket,
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  "Bagikan E-Ticket",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class RatingDialog extends StatefulWidget {
  final String venueName;

  const RatingDialog({super.key, required this.venueName});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedStars = 0;
  final TextEditingController _reviewController = TextEditingController();

  String _getRatingLabel() {
    switch (_selectedStars) {
      case 1: return "Sangat Buruk";
      case 2: return "Buruk";
      case 3: return "Cukup";
      case 4: return "Bagus";
      case 5: return "Sangat Bagus";
      default: return "Ketuk untuk memberi rating";
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon rating dengan tema biru
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_rounded,
                color: AppColors.primaryBlue,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              "Beri Penilaian",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              "Bagaimana pengalaman main di ${widget.venueName}?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Stars dengan container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      bool isSelected = index < _selectedStars;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStars = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? AppColors.primaryBlue : Colors.grey[400],
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Rating label
                  Text(
                    _getRatingLabel(),
                    style: TextStyle(
                      color: _selectedStars > 0 ? AppColors.primaryBlue : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Text field dengan border biru saat focus
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: "Tulis ulasan (opsional)...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Nanti Saja",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedStars > 0 ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Text("Terima kasih atas penilaiannya!"),
                            ],
                          ),
                          backgroundColor: AppColors.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Kirim",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}