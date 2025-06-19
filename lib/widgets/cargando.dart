import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingReloadWidget extends StatefulWidget {
  final Future<void> Function() loadDataFunction;
  final Widget child;
  final String loadingMessage;
  final String? errorTitle;
  final Duration animationDuration;

  const LoadingReloadWidget({
    super.key,
    required this.loadDataFunction,
    required this.child,
    this.loadingMessage = 'Cargando...',
    this.errorTitle,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<LoadingReloadWidget> createState() => _LoadingReloadWidgetState();
}

class _LoadingReloadWidgetState extends State<LoadingReloadWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await widget.loadDataFunction();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator()
              .animate()
              .fadeIn(duration: widget.animationDuration),
          const SizedBox(height: 16),
          Text(widget.loadingMessage)
              .animate()
              .fadeIn(duration: widget.animationDuration),
        ],
      ),
    ).animate().fadeIn(duration: widget.animationDuration);
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.errorTitle != null)
            Text(
              widget.errorTitle!,
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(duration: widget.animationDuration),
          const SizedBox(height: 8),
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ).animate().fadeIn(duration: widget.animationDuration),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ).animate().fadeIn(duration: widget.animationDuration),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ).animate().fadeIn(delay: widget.animationDuration),
        ],
      ),
    ).animate().fadeIn(duration: widget.animationDuration);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    return widget.child
        .animate()
        .fadeIn(duration: widget.animationDuration);
  }
}