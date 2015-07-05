SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";

CREATE TABLE IF NOT EXISTS `servers` (
  `id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `users` (
  `pid` int(11) NOT NULL,
  `auth` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


ALTER TABLE `servers`
  ADD PRIMARY KEY (`id`), ADD KEY `id` (`id`), ADD KEY `name` (`name`), ADD INDEX(`id`), ADD INDEX(`name`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`pid`), ADD KEY `pid` (`pid`), ADD KEY `auth` (`auth`), ADD KEY `name` (`name`), ADD KEY `lastseen` (`lastseen`), ADD INDEX(`pid`), ADD INDEX(`auth`), ADD INDEX(`name`), ADD INDEX(`lastseen`);

ALTER TABLE `servers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
  MODIFY `pid` int(11) NOT NULL AUTO_INCREMENT;