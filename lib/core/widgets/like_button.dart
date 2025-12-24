import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/like_service.dart';
import '../utils/auth_helpers.dart';
import '../theme/app_theme.dart';

class LikeButton extends StatefulWidget {
  final String serviceId;
  final String serviceType;
  final int initialLikesCount;
  final double iconSize;
  final bool showCount;
  final VoidCallback? onLikeChanged;

  const LikeButton({
    Key? key,
    required this.serviceId,
    required this.serviceType,
    required this.initialLikesCount,
    this.iconSize = 24.0,
    this.showCount = true,
    this.onLikeChanged,
  }) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  final LikeService _likeService = LikeService();
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.initialLikesCount;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkIfLiked();
    _listenToLikesCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _listenToLikesCount() {
    _likeService.getLikesCountStream(widget.serviceId, widget.serviceType).listen((count) {
      if (mounted) {
        setState(() {
          _likesCount = count;
        });
      }
    });
  }

  Future<void> _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final isLiked = await _likeService.isLiked(widget.serviceId, user.uid);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    // Check authentication first
    final isAuthenticated = await AuthHelpers.requireAuth(
      context,
      message: 'يجب تسجيل الدخول للإعجاب بالمكان',
    );
    
    if (!isAuthenticated || !mounted) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final wasLiked = await _likeService.toggleLike(
        widget.serviceId,
        widget.serviceType,
        user.uid,
        user.email ?? '',
      );

      // Animate the heart
      if (mounted) {
        _animationController.forward().then((_) {
          if (mounted) {
            _animationController.reverse();
          }
        });
      }

      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _isLoading = false;
        });
      }

      // Notify parent to refresh
      if (widget.onLikeChanged != null) {
        widget.onLikeChanged!();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _toggleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              )
            else
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey[600],
                  size: widget.iconSize,
                ),
              ),
            if (widget.showCount) ...[
              const SizedBox(width: 6),
              Text(
                '$_likesCount',
                style: TextStyle(
                  fontSize: widget.iconSize * 0.7,
                  fontWeight: FontWeight.w600,
                  color: _isLiked ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Simple like count display (non-interactive)
class LikeCountDisplay extends StatelessWidget {
  final int likesCount;
  final double iconSize;

  const LikeCountDisplay({
    Key? key,
    required this.likesCount,
    this.iconSize = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite,
          color: Colors.red,
          size: iconSize,
        ),
        const SizedBox(width: 4),
        Text(
          '$likesCount',
          style: TextStyle(
            fontSize: iconSize * 0.8,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
