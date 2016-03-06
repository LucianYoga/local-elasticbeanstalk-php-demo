<?php

/**
 * An example of how we can use PHP to connect from this container to our
 * MySQL container.
 * Note that we rely on:
 * * the init.sh script moving .env to /tmp/.env and populating the MySQL envronment varialbes
 * * PDO being loaded (via php5-mysql)
 * * the Dotenv package being loaded via composer
 */
require __DIR__ . '/../vendor/autoload.php';

// https://github.com/phusion/baseimage-docker#environment-variables
$dotenv = new Dotenv\Dotenv(sys_get_temp_dir());
$dotenv->load();
$dotenv->required(['DB_HOST', 'DB_DATABASE'])->notEmpty();

echo '<p>DB_HOST    : ' . getEnv('DB_HOST') . '</p>';
echo '<p>DB_DATABASE: ' . getEnv('DB_DATABASE') . '</p>';

// Try and connect to the database
$db = new PDO('mysql:host=' . getEnv('DB_HOST') . ';dbname=' . getEnv('DB_DATABASE') . ';charset=utf8mb4', 'root', getEnv('DB_PASSWORD'));

if ($db === false) {
    echo "connection was not successful";
} else {
    $query = "SELECT COUNT(DISTINCT `table_name`) AS 'TABLE_COUNT' FROM `information_schema`.`columns` WHERE `table_schema` = 'my_db';";
    $results = $db->query($query);

    while($row = $results->fetch(PDO::FETCH_ASSOC)) {
        echo 'Number of tables in database ' . getEnv('DB_DATABASE') . ': ' . $row['TABLE_COUNT'];
    }
}
