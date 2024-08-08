use unigpt_auth;
CREATE TABLE auth (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL,
    is_admin TINYINT(1) DEFAULT 0
);