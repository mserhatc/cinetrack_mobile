<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */
$routes->get('/', 'Home::index');

$registerApiRoutes = function ($routes) {
    // -------------------------------------------------------------
    // Public Endpoints (Requires valid X-API-KEY header)
    // -------------------------------------------------------------
    // Auth: Register & Login
    $routes->post('auth/register', 'AuthController::register');
    $routes->post('auth/login', 'AuthController::login');
    $routes->get('auth/profile/(:num)', 'AuthController::profile/$1');

    // Feed / Posts - Read Only
    $routes->get('feed', 'FeedController::index');
    $routes->get('feed/user', 'FeedController::userPosts');
    $routes->get('feed/user/(:num)', 'FeedController::userPosts/$1');
    $routes->get('feed/comments/(:num)', 'FeedController::getComments/$1');

    // TMDB Proxy (Tokens handled securely on backend)
    $routes->get('tmdb/trending', 'TmdbController::trending');
    $routes->get('tmdb/search', 'TmdbController::search');
    $routes->get('tmdb/popular/movies', 'TmdbController::popularMovies');
    $routes->get('tmdb/popular/tv', 'TmdbController::popularTv');
    $routes->get('tmdb/movie/(:num)', 'TmdbController::movieDetails/$1');
    $routes->get('tmdb/tv/(:num)', 'TmdbController::tvDetails/$1');

    // Watchlist & Reviews - Read Only
    $routes->get('watchlist/reviews/(:num)/(:segment)', 'WatchlistController::getReviews/$1/$2');

    // Users & Social - Read Only
    $routes->get('user/followers/(:num)', 'UserController::getFollowers/$1');
    $routes->get('user/following/(:num)', 'UserController::getFollowing/$1');
    $routes->get('user/watched/movies/(:num)', 'UserController::getWatchedMovies/$1');
    $routes->get('user/watched/shows/(:num)', 'UserController::getWatchedShows/$1');
    $routes->get('user/watchlist/(:num)', 'UserController::getWatchlist/$1');

    // -------------------------------------------------------------
    // Protected Endpoints (Requires X-API-KEY + Bearer Token)
    // -------------------------------------------------------------
    $routes->group('', ['filter' => 'auth'], function ($routes) {
        // Authenticated user's own profile & update
        $routes->get('auth/profile', 'AuthController::profile');
        $routes->post('auth/update', 'AuthController::updateProfile');

        // Feed / Posts Actions
        $routes->post('feed/create', 'FeedController::create');
        $routes->put('feed/post/(:num)', 'FeedController::updatePost/$1');
        $routes->post('feed/post/update/(:num)', 'FeedController::updatePost/$1');
        $routes->delete('feed/post/(:num)', 'FeedController::deletePost/$1');
        $routes->post('feed/post/delete/(:num)', 'FeedController::deletePost/$1');
        $routes->post('feed/like/(:num)', 'FeedController::toggleLike/$1');

        // Comments Actions
        $routes->post('feed/comment/(:num)', 'FeedController::addComment/$1');
        $routes->put('feed/comment/(:num)', 'FeedController::updateComment/$1');
        $routes->post('feed/comment/update/(:num)', 'FeedController::updateComment/$1');
        $routes->delete('feed/comment/(:num)', 'FeedController::deleteComment/$1');
        $routes->post('feed/comment/delete/(:num)', 'FeedController::deleteComment/$1');
        $routes->post('feed/comment/like/(:num)', 'FeedController::toggleCommentLike/$1');

        // Watchlist & Ratings Actions
        $routes->post('watchlist/status', 'WatchlistController::setStatus');
        $routes->post('watchlist/rate', 'WatchlistController::rateAndReview');

        // Social Actions
        $routes->post('user/follow/(:num)', 'UserController::toggleFollow/$1');
    });
};

// Mount under both 'api' and 'api/v1' with ApiKeyFilter
$routes->group('api', ['namespace' => 'App\Controllers\Api', 'filter' => 'apiKey'], $registerApiRoutes);
$routes->group('api/v1', ['namespace' => 'App\Controllers\Api', 'filter' => 'apiKey'], $registerApiRoutes);
