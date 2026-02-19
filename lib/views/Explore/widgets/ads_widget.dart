import 'package:flutter/material.dart';

class AdItem {
  final String imageUrl;
  final VoidCallback onTap;

  AdItem({required this.imageUrl, required this.onTap});
}

class AdsWidget extends StatefulWidget {
  final List<AdItem> ads;

  const AdsWidget({Key? key, required this.ads}) : super(key: key);

  @override
  _AdsWidgetState createState() => _AdsWidgetState();
}

class _AdsWidgetState extends State<AdsWidget> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  void _nextAd() {
    if (_currentIndex < widget.ads.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = 0;
    }
    _controller.animateToPage(
      _currentIndex,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.ads.length,
            itemBuilder: (context, index) {
              final ad = widget.ads[index];

              return GestureDetector(
                onTap: ad.onTap,
                child: Container(
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.purple[800],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            ad.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black,
                              Colors.transparent,
                            ], // start to end colors
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sponsored by NIKE",
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Discover the brand new collection",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Center(
                      //   child: Opacity(
                      //     opacity: 0.9,
                      //     child: Image.asset(
                      //       'assets/nike_logo.png',
                      //       height: 100,
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Positioned(
            right: 20,
            top: 90,
            child: GestureDetector(
              onTap: _nextAd,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_forward_ios, color: Colors.purple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
