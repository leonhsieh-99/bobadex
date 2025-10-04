import 'dart:async';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ThumbPic extends StatefulWidget {
  final String? path;
  final double size;
  final String? initials;
  final VoidCallback? onTap;

  const ThumbPic({
    super.key,
    required this.path,
    this.size = 40,
    this.initials,
    this.onTap,
  });

  @override
  State<ThumbPic> createState() => _ThumbPicState();
}

class _ThumbPicState extends State<ThumbPic> {
  int _which = 0;
  int _attempt = 0;
  final int _maxAttempts = 3;
  bool _giveUp = false;
  Timer? _retryTimer;
  bool _retryScheduled = false;

  String? _lastPath;
  double? _lastSize;
  int? _lastPx;

  @override
  void initState() {
    super.initState();
    if ((widget.path ?? '').trim().isEmpty) _giveUp = true;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _resetProgress() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryScheduled = false;
    _which = 0;
    _attempt = 0;
    _giveUp = (widget.path == null || widget.path!.trim().isEmpty);
  }

  void _scheduleRetry() {
    if (!mounted || _retryScheduled || _giveUp) return;
    _retryScheduled = true;
    final delay = Duration(milliseconds: (400 * (1 << _attempt)).clamp(400, 4000));
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      _retryScheduled = false;
      setState(() {
        _attempt += 1;
        if (_attempt >= _maxAttempts) {
          _attempt = 0;
          if (_which < 2) {
            _which += 1; // next candidate
          } else {
            _giveUp = true; // all tried
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_giveUp) return _fallback();

    final path = (widget.path ?? '').trim();
    if (path.isEmpty) return _fallback();

    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
    final px  = pickSquareSize(widget.size, dpr, Constants.thumbSizes);

    // If input changed (path/size/px), reset retry state
    if (_lastPath != path || _lastSize != widget.size || _lastPx != px) {
      _lastPath = path;
      _lastSize = widget.size;
      _lastPx = px;
      _resetProgress();
    }

    String u(String p) => publicUrl(Constants.imageBucket, p);
    final candidates = <String>[
      u(thumbPath(path, px)),   // s512/s256 depending on px
      u(thumbPath(path, 256)),  // common fallback
      u(path),                  // original
    ];
    final url = candidates[_which];

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          cacheKey: '$url@${widget.size}',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          memCacheWidth:  _which == 1 ? 256 : null,
          memCacheHeight: _which == 1 ? 256 : null,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleRetry());
            return _placeholder();
          },
        ),
      ),
    );
  }

  Widget _placeholder() => SizedBox(
    width: widget.size, height: widget.size,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );

  Widget _fallback() {
    final text = (widget.initials ?? '').trim();
    if (text.isNotEmpty) {
      final abbr = _oneChar(text).toUpperCase();
      return Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade400),
        alignment: Alignment.center,
        child: Text(abbr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: widget.size * 0.45)),
      );
    }
    return Container(
      width: widget.size, height: widget.size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
      child: Icon(Icons.person, size: widget.size * 0.5, color: Colors.white),
    );
  }

  String _oneChar(String s) => s.replaceAll(RegExp(r'\s+'), '').characters.take(1).toString();
}
