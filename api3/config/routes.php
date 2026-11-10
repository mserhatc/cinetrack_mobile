<?php
defined('BASEPATH') OR exit('No direct script access allowed');

/*
| -------------------------------------------------------------------------
| URI ROUTING
| -------------------------------------------------------------------------
| This file lets you re-map URI requests to specific controller functions.
|
| Typically there is a one-to-one relationship between a URL string
| and its corresponding controller class/method. The segments in a
| URL normally follow this pattern:
|
|	example.com/class/method/id/
|
| In some instances, however, you may want to remap this relationship
| so that a different class/function is called than the one
| corresponding to the URL.
|
| Please see the user guide for complete details:
|
|	https://codeigniter.com/userguide3/general/routing.html
|
| -------------------------------------------------------------------------
| RESERVED ROUTES
| -------------------------------------------------------------------------
|
| There are three reserved routes:
|
|	$route['default_controller'] = 'welcome';
|
| This route indicates which controller class should be loaded if the
| URI contains no data. In the above example, the "welcome" class
| would be loaded.
|
|	$route['404_override'] = 'errors/page_missing';
|
| This route will tell the Router which controller/method to use if those
| provided in the URL cannot be matched to a valid route.
|
|	$route['translate_uri_dashes'] = FALSE;
|
| This is not exactly a route, but allows you to automatically route
| controller and method names that contain dashes. '-' isn't a valid
| class or method name character, so it requires translation.
| When you set this option to TRUE, it will replace ALL dashes in the
| controller and method URI segments.
|
| Examples:	my-controller/index	-> my_controller/index
|		my-controller/my-method	-> my_controller/my_method
*/
$route['default_controller'] = 'welcome';
$route['404_override'] = '';
$route['translate_uri_dashes'] = FALSE;

// ==========================================
// CINETRACK REST API ROUTES
// ==========================================
// Auth
$route['api/auth/register'] = 'api/auth/register';
$route['api/auth/login'] = 'api/auth/login';
$route['api/auth/profile'] = 'api/auth/profile';
$route['api/auth/profile/(:num)'] = 'api/auth/profile/$1';
$route['api/auth/update'] = 'api/auth/updateProfile';

// Feed / Posts
$route['api/feed'] = 'api/feed/index';
$route['api/feed/create'] = 'api/feed/create';
$route['api/feed/post/(:num)'] = 'api/feed/post/$1';
$route['api/feed/post/update/(:num)'] = 'api/feed/updatePost/$1';
$route['api/feed/post/delete/(:num)'] = 'api/feed/deletePost/$1';
$route['api/feed/user'] = 'api/feed/userPosts';
$route['api/feed/user/(:num)'] = 'api/feed/userPosts/$1';
$route['api/feed/like/(:num)'] = 'api/feed/toggleLike/$1';
$route['api/feed/comments/(:num)'] = 'api/feed/getComments/$1';
$route['api/feed/comment/(:num)'] = 'api/feed/comment/$1';
$route['api/feed/comment/update/(:num)'] = 'api/feed/updateComment/$1';
$route['api/feed/comment/delete/(:num)'] = 'api/feed/deleteComment/$1';
$route['api/feed/comment/like/(:num)'] = 'api/feed/toggleCommentLike/$1';

// TMDB Proxy
$route['api/tmdb/trending'] = 'api/tmdb/trending';
$route['api/tmdb/search'] = 'api/tmdb/search';
$route['api/tmdb/popular/movies'] = 'api/tmdb/popularMovies';
$route['api/tmdb/popular/tv'] = 'api/tmdb/popularTv';
$route['api/tmdb/movie/(:num)'] = 'api/tmdb/movieDetails/$1';
$route['api/tmdb/tv/(:num)'] = 'api/tmdb/tvDetails/$1';

// Watchlist & Reviews
$route['api/watchlist/status'] = 'api/watchlist/setStatus';
$route['api/watchlist/rate'] = 'api/watchlist/rateAndReview';
$route['api/watchlist/reviews/(:num)/(:any)'] = 'api/watchlist/getReviews/$1/$2';

// Users & Social
$route['api/user/follow/(:num)'] = 'api/user/toggleFollow/$1';
$route['api/user/followers/(:num)'] = 'api/user/getFollowers/$1';
$route['api/user/following/(:num)'] = 'api/user/getFollowing/$1';
$route['api/user/watched/movies/(:num)'] = 'api/user/getWatchedMovies/$1';
$route['api/user/watched/shows/(:num)'] = 'api/user/getWatchedShows/$1';
$route['api/user/watchlist/(:num)'] = 'api/user/getWatchlist/$1';

// V1 Alias
$route['api/v1/(.+)'] = 'api/$1';
