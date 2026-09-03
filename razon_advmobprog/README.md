# Renzy Anne Mae A. Razon

## INF233

## CTADMOBPL Advanced Mobile Programming
A Flutter project that focuses on advance topics. Covering the web to mobile transactions.

## Lab Activity Instance

## Laboratory List
- Laboratory Activity 1 (Theme Dark/Light Model) - This lab activity is all about learning the difference between ephemeral and app state in Flutter and how to manage them effectively. For my first screen, I used setState to manage the local state of the counter since it only matters to that specific widget. On the other hand, I used Provider with ChangeNotifier on my second screen to handle the global app state for the theme toggle. Calling setState only triggers a rebuild for the local counter, whereas notifyListeners() in Provider updates the theme across all screens. Overall, setState is best for simple UI updates, while Provider is better for shared data like app preferences.

- Laboratory Activity 2 (Product API and Theme Model) - This lab activity shows how using the MVC/Service design pattern keeps a Flutter app organized by separating data, code logic, and screen design. The Product Model defines what a product looks like, while the Product Service fetches data from the API and converts it into usable objects. The app screens then call the service to fetch and show this product data to the user. Putting models, services, providers, and screens into separate files makes the code much cleaner and easier to work on. This setup easily powers main features like product search, a product details page, and switching between light and dark mode using Provider.

- Laboratory Activity 3 (Cart API Integration) - In this activity, I learned how to add a cart feature to our Flutter application using the API. I understood better how the cart model, service, and screen work together to get and display data from the API. I also learned how to get a specific user's cart and add products to the cart using the given endpoints. Changing the chat option into a FloatingActionButton also helped me understand how small UI changes can make the app more organized and easier to use. Overall, this activity helped me become more familiar with connecting API data to different screens and organizing my Flutter code properly.

- Laboratory Activity 4 (Service, Model & Screen Integration) - In this activity, I learned how the service, model, and screen components work together by having UserService fetch raw API data, convert it into a User model, and pass it to profile_screen for rendering. Using a separated file structure helped organize our code by keeping business logic separate from the UI components. For cart_screen, we utilized persistent data by saving the userId into SharedPreferences during login and retrieving it to fetch the user-specific cart. Overall, this lab made me appreciate how structured architecture keeps state management clean and makes data easily accessible across screens.

