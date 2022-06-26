class RingNumberProvider {
  RingNumberProvider(this._vals);

  final List<double> _vals;
  int _idx = 0;

  double get next {
    if (_idx >= _vals.length) {
      _idx = 0;
    }
    return _vals[_idx++];
  }
}
