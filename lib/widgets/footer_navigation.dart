import 'package:flutter/material.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double fabSize;
  final String? profileImageUrl; // optional profile image url

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.fabSize = 80,
    this.profileImageUrl,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _centerController;
  late List<AnimationController> _iconControllers;

  @override
  void initState() {
    super.initState();
    _centerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.9,
      upperBound: 1.0,
    );

    _iconControllers = List.generate(4, (_) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        lowerBound: 0.9,
        upperBound: 1.0,
      );
    });
  }

  @override
  void dispose() {
    _centerController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCenterTap() async {
    await _centerController.forward();
    await _centerController.reverse();
    widget.onTap(2);
  }

  void _onIconTap(int controllerIndex, int pageIndex) async {
    await _iconControllers[controllerIndex].forward();
    await _iconControllers[controllerIndex].reverse();
    widget.onTap(pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    double navHeight = widget.fabSize > 60 ? 85 : 80;

    return Container(
      height: navHeight,
      decoration: BoxDecoration(
        color: Colors.green.shade900,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                iconItem(Icons.people, "Attendance", 0, 0),
                iconItem(Icons.account_balance_outlined, "Balance", 1, 1),
                SizedBox(width: widget.fabSize),
                iconItem(Icons.bar_chart, "Inventory", 2, 3),
                profileItem(3, 4), // custom profile with image or fallback
              ],
            ),
          ),
          Positioned(
            top: -widget.fabSize / 4,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: _centerController,
                child: GestureDetector(
                  onTap: _onCenterTap,
                  child: Container(
                    height: widget.fabSize,
                    width: widget.fabSize,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: widget.currentIndex == 2
                          ? Colors.white
                          : Colors.black,
                      size: widget.fabSize * 0.55,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget iconItem(IconData icon, String label, int controllerIndex, int pageIndex) {
    return ScaleTransition(
      scale: _iconControllers[controllerIndex],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _onIconTap(controllerIndex, pageIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: widget.currentIndex == pageIndex
                      ? Colors.orange
                      : Colors.black,
                  size: 30,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.currentIndex == pageIndex
                        ? Colors.orange
                        : Colors.black,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget profileItem(int controllerIndex, int pageIndex) {
    return ScaleTransition(
      scale: _iconControllers[controllerIndex],
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _onIconTap(controllerIndex, pageIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.profileImageUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(widget.profileImageUrl!),
                        radius: 15,
                      )
                    : Icon(
                        Icons.person_outline,
                        color: widget.currentIndex == pageIndex
                            ? Colors.orange
                            : Colors.black,
                        size: 30,
                      ),
                const SizedBox(height: 4),
                Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.currentIndex == pageIndex
                        ? Colors.orange
                        : Colors.black,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
