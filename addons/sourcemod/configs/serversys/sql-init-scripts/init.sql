SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";

CREATE TABLE IF NOT EXISTS `servers` (
  `id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `ip` varchar(64) NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `users` (
  `pid` int(11) NOT NULL,
  `auth` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `lastseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `playtime` (
  `row` int(11) NOT NULL,
  `pid` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `time` int(32) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


ALTER TABLE `servers`
  ADD PRIMARY KEY (`id`), ADD KEY `id` (`id`), ADD KEY `name` (`name`), ADD INDEX(`id`), ADD INDEX(`name`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`pid`), ADD KEY `pid` (`pid`), ADD KEY `auth` (`auth`), ADD KEY `name` (`name`), ADD KEY `lastseen` (`lastseen`), ADD INDEX(`pid`), ADD INDEX(`auth`), ADD INDEX(`name`), ADD INDEX(`lastseen`);

ALTER TABLE `playtime`
  ADD PRIMARY KEY (`row`), ADD KEY `row` (`row`), ADD KEY `pid` (`pid`), ADD KEY `sid` (`sid`), ADD KEY `time` (`time`), ADD INDEX(`row`), ADD INDEX(`pid`), ADD INDEX(`sid`), ADD INDEX(`time`);


ALTER TABLE `servers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
  MODIFY `pid` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `playtime`
  MODIFY `row` int(11) NOT NULL AUTO_INCREMENT;
