import 'package:conduit_core/conduit_core.dart';

class User extends ManagedObject<_User> implements _User {}

// все модели которые имплиментирует ManagedObject автоматически сопоставляются с табицами базы данных
class _User {
  @primaryKey
  int? id;
  @Column(unique: true, indexed: true)
  String? username;
  @Column(unique: true, indexed: true)
  String? email;
  @Column(nullable: true)
  String? firstname;
  @Column(nullable: true)
  String? surname;
  @Column(nullable: true)
  String? patronymic;
  @Serialize(input: true, output: false)
  String? password;
  @Column(nullable: true)
  String? accessToken;
  @Column(nullable: true)
  String? refreshToken;
  //в базе данных записываем, но  при запросе не возвращаем
  @Column(omitByDefault: true)
  String? salt;
  @Column(omitByDefault: true)
  String? hashPassword;
}
