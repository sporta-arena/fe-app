import 'package:flutter/material.dart';

class VenueListPage extends StatelessWidget {
  const VenueListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data sesuai gambar kamu
    final List<Map<String, dynamic>> venues = [
      {
        "name": "Futsal Arena Champions",
        "location": "Kemang, Jakarta Selatan",
        "distance": "2.4 km",
        "price": 150000,
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=600&auto=format&fit=crop", // Gambar Futsal Asli
        "facilities": ["Parkir", "Kantin", "AC", "WiFi"],
        "isAvailable": true,
      },
      {
        "name": "Sporta Futsal Center",
        "location": "Tebet, Jakarta Selatan",
        "distance": "3.1 km",
        "price": 120000,
        "rating": 4.7,
        "image": "https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=600&auto=format&fit=crop",
        "facilities": ["Parkir", "Musholla"],
        "isAvailable": true,
      },
      {
        "name": "Galaxy Sports Hall",
        "location": "Bekasi Barat",
        "distance": "5.0 km",
        "price": 180000,
        "rating": 4.5,
        "image": "https://images.unsplash.com/photo-1596230529625-7ee541ccbd6e?q=80&w=600&auto=format&fit=crop",
        "facilities": ["Tribun", "Locker", "Shower"],
        "isAvailable": false, // Penuh
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background abu sangat muda biar kartu menonjol
      appBar: AppBar(
        title: const Text(
          "Lapangan Futsal", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black), 
            onPressed: () {}
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. FILTER BAR (Dibuat lebih modern) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip(Icons.tune, "Filter"),
                const SizedBox(width: 10),
                _buildFilterChip(Icons.sort, "Urutkan"),
                const SizedBox(width: 10),
                // Quick Filter: Terdekat
                Expanded(
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "Terdekat", 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.grey
                      )
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. LIST VENUE ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                return VenueCardModern(data: venues[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget: Tombol Filter
  Widget _buildFilterChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            label, 
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            )
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET KARTU VENUE (MODERN STYLE)
// ==========================================
class VenueCardModern extends StatelessWidget {
  final Map<String, dynamic> data;

  const VenueCardModern({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    bool isAvailable = data['isAvailable'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Sudut lebih membulat
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. GAMBAR (IMMERSIVE) ---
          Stack(
            children: [
              // Foto Lapangan
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  data['image'],
                  height: 180, // Gambar lebih tinggi biar puas lihatnya
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),

              // Badge Rating - Pojok Kanan Atas
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${data['rating']}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- 2. INFORMASI VENUE ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama & Jarak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data['name'],
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          height: 1.2
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Jarak (Icon + Text)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text(
                          data['distance'],
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey[600]
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Lokasi Lengkap
                Text(
                  data['location'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),

                // Fasilitas (Chips)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (data['facilities'] as List<String>).map((facility) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FF), // Biru sangat muda
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE1E9FF)),
                        ),
                        child: Text(
                          facility,
                          style: const TextStyle(
                            fontSize: 10, 
                            color: Color(0xFF0047FF), 
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // --- 3. FOOTER (HARGA & TOMBOL) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Harga
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mulai dari", 
                          style: TextStyle(fontSize: 10, color: Colors.grey[500])
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Rp ${data['price'] ~/ 1000}", // Format ribuan simpel (150)
                                style: const TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.w900, 
                                  color: Color(0xFF0047FF), 
                                  fontFamily: 'GeneralSans'
                                ),
                              ),
                              TextSpan(
                                text: ".000 /jam",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Tombol Book
                    ElevatedButton(
                      onPressed: isAvailable ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0047FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        isAvailable ? "Book" : "Penuh",
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}