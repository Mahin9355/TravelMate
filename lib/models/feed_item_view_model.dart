import 'post_model.dart';
import 'user_model.dart';

class FeedItemViewModel {
  final PostModel post;
  final UserModel user;

  FeedItemViewModel({required this.post, required this.user});
}