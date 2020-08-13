## 环境
- PhpStorm：2018.1
- 织梦CMS：V5.75 SP1 UTf-8


## 使用
我在Dockerfile中只暴露了80端口，使用时需要在config中添加端口转发。

因为
```shell
RUN pecl channel-update pecl.php.net
RUN pecl install xdebug-2.5.5 && docker-php-ext-enable xdebug
```
需要翻墙才行，所以你需要一个全局梯子，不然会出现：``` No releases available for package "pecl.php.net/xdebug" ```


### 验证安装
```bash
docker run -it --rm php:7.0.30-apache-jessie /bin/bash
```

交流QQ：260240310

## 版权
关于织梦CMS，版权归官方所有。

本项目只是针对他搭建了一个docker的测试运行环境。