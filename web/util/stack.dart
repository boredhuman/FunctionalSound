class Stack<E> {
  final _list = <E>[];
  int maxSize = 0;

  void push(E value) {
    _list.add(value);

    if (_list.length > maxSize) {
      maxSize = _list.length;
    }
  }

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
}
