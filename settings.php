<?php

/**
 * @file
 */

use Symfony\Component\Dotenv\Dotenv;

$dotenv = new Dotenv();
$dotenv->load(__DIR__ . "/../../../.env");

// Fix https from reverse-proxy
global $request;
$proto =
  $request && $request->server
    ? $request->server->get("HTTP_X_FORWARDED_PROTO")
    : null;
if (!empty($proto) && $proto === "https") {
  $request->server->set("HTTPS", "on");
}

/**
 * Salt for one-time login links, cancel links, form tokens, etc.
 */
$settings["hash_salt"] = $_ENV["HASH_SALT"];

/**
 * Access control for update.php script.
 */
$settings["update_free_access"] = false;

/**
 * Load services definition file.
 */
$settings["container_yamls"][] = $app_root . "/" . $site_path . "/services.yml";

/**
 * The default list of directories that will be ignored by Drupal's file API.
 */
$settings["file_scan_ignore_directories"] = [
  "node_modules",
  "bower_components",
];

/**
 * The default number of entities to update in a batch process.
 */
$settings["entity_update_batch_size"] = 50;

/**
 * Disable rebuil access.
 */
$settings["rebuild_access"] = false;

/**
 * Entity update backup.
 */
$settings["entity_update_backup"] = true;

$settings["config_sync_directory"] = "../config/sync";

$settings["file_private_path"] = "sites/default/files/private";

// Database.
$databases["default"]["default"] = [
  "host" => $_ENV["DB_HOST"] ?? "mysql",
  "port" => $_ENV["DB_PORT"] ?? "3306",
  "database" => $_ENV["DB_NAME"] ?? $_ENV["PROJECT"],
  "username" => $_ENV["DB_USER"] ?? "root",
  "password" => $_ENV["DB_PASS"] ?? "root",
  "prefix" => $_ENV["DB_PREFIX"] ?? "",
  "driver" => $_ENV["DB_DRIVER"] ?? "mysql",
  "namespace" =>
    "Drupal\\Core\\Database\\Driver\\" . ($_ENV["DB_DRIVER"] ?? "mysql"),
];

// Host patterns.
if (!empty($_ENV["TRUSTED_HOST_PATTERNS"])) {
  $settings["trusted_host_patterns"] = [$_ENV["TRUSTED_HOST_PATTERNS"]];
}
