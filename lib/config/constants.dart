class Constants {
  static const defaultTheme = 'classic_milk_tea';
  static const useIcons = true;
  static const useMascots = true;
  static const defaultGridColumns = 2;

  static const int maxFileSize = 10 * 1024 * 1024;
  static const int defaultFeedLimit = 50;
  static const int defaultGalleryLimit = 20;
  static const int snackBarDuration = 2900; // milliseconds
  static const int otpResendCooldownSeconds = 60;
  // image sizes
  static const thumbSizes = <int>[256, 512];
  static const String imageBucket = 'media-uploads';
  static const String iconBucket = 'shop-media';

  static const int maxUsernameLength = 20;
  static const int maxNameLength = 40;
  static const int maxShopNotesLength = 120;
  static const int maxDrinkNameLength = 35;
  static final emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  static final int maxDrinkCountForFetchAll = 300;
}
