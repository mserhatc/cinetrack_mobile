CREATE DATABASE IF NOT EXISTS cinetrack_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cinetrack_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) DEFAULT '',
    avatar VARCHAR(255) DEFAULT '',
    bio TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS follows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_follower_following (follower_id, following_id),
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    post_type ENUM('quote', 'review', 'general') DEFAULT 'general',
    tmdb_id INT NULL,
    media_type ENUM('movie', 'tv') DEFAULT 'movie',
    title VARCHAR(255) DEFAULT '',
    poster_path VARCHAR(255) DEFAULT '',
    quote_text TEXT,
    content TEXT,
    rating DECIMAL(3,1) NULL,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS post_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_post_user (post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS post_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS watchlist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    tmdb_id INT NOT NULL,
    media_type ENUM('movie', 'tv') DEFAULT 'movie',
    title VARCHAR(255) NOT NULL,
    poster_path VARCHAR(255) DEFAULT '',
    status ENUM('watched', 'plan_to_watch') DEFAULT 'plan_to_watch',
    rating DECIMAL(3,1) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_media (user_id, tmdb_id, media_type),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS media_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    tmdb_id INT NOT NULL,
    media_type ENUM('movie', 'tv') DEFAULT 'movie',
    title VARCHAR(255) NOT NULL,
    poster_path VARCHAR(255) DEFAULT '',
    rating DECIMAL(3,1) NOT NULL,
    review_text TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Test kullanıcısı ve örnek veriler ekleyelim
INSERT IGNORE INTO users (id, username, email, password_hash, full_name, bio) VALUES
(1, 'ahmet_film', 'ahmet@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Ahmet Yılmaz', 'Sinema ve dizi tutkunu, Nolan hayranı.'),
(2, 'zeynep_dizi', 'zeynep@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Zeynep Kaya', 'Sci-Fi ve Gizem dizileri koleksiyoncusu.');
-- (Şifre: 'password')

INSERT IGNORE INTO follows (follower_id, following_id) VALUES (1, 2);

INSERT IGNORE INTO posts (id, user_id, post_type, tmdb_id, media_type, title, poster_path, quote_text, content, rating, likes_count) VALUES
(1, 1, 'quote', 27205, 'movie', 'Inception', '/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 'Bir fikrin tohumunu ekerseniz, o büyür ve sizi ya tanımlar ya da yok eder.', 'Her izlediğimde aklımı başımdan alan bir başyapıt.', 9.5, 12),
(2, 2, 'review', 1399, 'tv', 'Game of Thrones', '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg', NULL, 'Kış geliyor! İlk 4 sezon dizi tarihinin en iyi yapımlarından biriydi. Karakter derinliği ve müzikler olağanüstü.', 9.0, 24),
(3, 1, 'quote', 155, 'movie', 'The Dark Knight', '/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'Ya bir kahraman olarak ölürsün ya da kötü adam oluşunu izleyecek kadar uzun yaşarsın.', 'Heath Ledger efsanesi.', 10.0, 35);

INSERT IGNORE INTO watchlist (user_id, tmdb_id, media_type, title, poster_path, status, rating) VALUES
(1, 27205, 'movie', 'Inception', '/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 'watched', 9.5),
(1, 155, 'movie', 'The Dark Knight', '/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'watched', 10.0),
(1, 1399, 'tv', 'Game of Thrones', '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg', 'watched', 9.0),
(1, 680, 'movie', 'Pulp Fiction', '/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', 'plan_to_watch', NULL);

