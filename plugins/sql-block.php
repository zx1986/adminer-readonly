<?php

/** Block dangerous SQL queries
* @link https://www.adminer.org/plugins/#use
* @author Hsu Chang <zx1986@gmail.com>
* @license https://www.apache.org/licenses/LICENSE-2.0 Apache License, Version 2.0
*/
class AdminerSqlBlock extends Adminer\Plugin {
  protected $filename;

  /**
  * @param string $filename defaults to "$database.sql"
  */
  function __construct($filename = "") {
    $this->filename = $filename;
  }

  function messageQuery($query, $time, $failed = false) {
    if ($this->isDangerousQuery($query)) {
      return "Dangerous Query is not allow: " . htmlspecialchars($query);
    }
    return $query;
  }

  function sqlCommandQuery($query) {
    if ($this->isDangerousQuery($query)) {
      return "Dangerous Query is not allow: " . htmlspecialchars($query);
    }
    return $query;
  }

  private function isDangerousQuery($query) {
    if ($_SESSION["username"] === "admin") {
      return false;  // allow admin to do dangerous operations
    }
    return preg_match('/^\s*(DELETE|DROP|TRUNCATE|UPDATE)\b/i', $query);
  }

  private function loggingDangerousQuery($query) {
    if ($this->filename == "") {
      $this->filename = Adminer\adminer()->database() . ($_GET["ns"] != "" ? ".$_GET[ns]" : "") . ".sql"; // no database goes to ".sql" to avoid collisions
    }
    $fp = fopen($this->filename, "a");
    flock($fp, LOCK_EX);
    fwrite($fp, $query);
    fwrite($fp, "\n\n");
    flock($fp, LOCK_UN);
    fclose($fp);
  }

}
