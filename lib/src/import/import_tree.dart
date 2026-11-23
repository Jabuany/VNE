typedef TreeEntry = ({String id, String name, bool isDirectory, int? size});

abstract interface class ImportTree {
  String get root;
  String get title;
  Stream<TreeEntry> children(String directory);
  Stream<List<int>> read(String file, {int? limit});
  Future<void> retainReference();
  Future<void> close();
}
