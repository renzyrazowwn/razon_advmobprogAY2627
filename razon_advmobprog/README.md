# Renzy Anne Mae A. Razon

## INF233

## CTADMOBPL Advanced Mobile Programming
A Flutter project that focuses on advance topics. Covering the web to mobile transactions.

## Lab Activity Instance

## Laboratory List
- Laboratory Activity 1 (Theme Dark/Light Model) - This lab activity is all about learning the difference between ephemeral and app state in Flutter and how to manage them effectively. For my first screen, I used setState to manage the local state of the counter since it only matters to that specific widget. On the other hand, I used Provider with ChangeNotifier on my second screen to handle the global app state for the theme toggle. Calling setState only triggers a rebuild for the local counter, whereas notifyListeners() in Provider updates the theme across all screens. Overall, setState is best for simple UI updates, while Provider is better for shared data like app preferences.

- Laboratory Activity 2 (Product API and Theme Model) - This lab activity shows how using the MVC/Service design pattern keeps a Flutter app organized by separating data, code logic, and screen design. The Product Model defines what a product looks like, while the Product Service fetches data from the API and converts it into usable objects. The app screens then call the service to fetch and show this product data to the user. Putting models, services, providers, and screens into separate files makes the code much cleaner and easier to work on. This setup easily powers main features like product search, a product details page, and switching between light and dark mode using Provider.