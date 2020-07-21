typedef ComputeCallback<Q, R> = R Function(Q message);

Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message,
    {String debugLabel}) async {
  return callback(message);
}
