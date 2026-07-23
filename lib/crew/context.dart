/// Shared blackboard passed between agents in sequential order.
class CrewContext {
  CrewContext({Map<String, dynamic>? seed}) : data = {...?seed};

  final Map<String, dynamic> data;

  T? get<T>(String key) {
    final value = data[key];
    if (value is T) return value;
    return null;
  }

  void set(String key, Object? value) {
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
