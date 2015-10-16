CREATE TABLE `ad` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `city` varchar(50) DEFAULT NULL,
  `source` varchar(50) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `type` varchar(50) DEFAULT NULL,
  `summary` TEXT,
  `locality` varchar(100) DEFAULT NULL,
  `price` varchar(50) DEFAULT NULL,
  `time` varchar(50) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  `contact_name` varchar(50) DEFAULT NULL,
  `contact_number` varchar(50) DEFAULT NULL,
  `added_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `city` (`city`),
  KEY `source` (`source`),
  UNIQUE KEY `link` (`link`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
