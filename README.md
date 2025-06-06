# Postgrinstall
<br>

**Postgrinstall** - небольшая программа для установки PostgreSQL на менее загруженный из двух серверов с операционными системами Debian и AlmaLinux (CentOS).<br><br>
Программа создана для запуска на Linux. Её запуск на Windows не тестировался и не поддерживается.

## Перед запуском

1. Создайте пару ключей ssh и назовите ключ, которым будете подключаться к серверам, `ansible_key`. Убедитесь, что оба ключа находятся в домашней директории пользователя, который будет запускать скрипт, в папке `.ssh`.<br><br>
2. Настройте подключение по ssh к двум необходимым серверам. Проверьте, что хост, с которого будет запускаться программа, может к ним подключиться как пользователь `root` по ключу и без ввода пароля.<br><br>
3. Проверьте, что у всех машин есть доступ в интернет для скачивания необходимых пакетов.<br><br>
4. Установите `Python 3` и `Ansible` по официальным инструкциям. Убедитесь, что на вашей системе Python запускается через команду `python3`.<br><br>

## Запуск

1. Клонируйте репозиторий командой:
```
git clone https://github.com/pipo-cxx/postgrinstall.git
```

2. Перейдите в папку с клонированным репозиторием.

3. Сделайте файл `postgrinstall.sh` исполняемым с помощью:
```
sudo chmod +x postgrinstall.sh
```

4. Запустите файл:
```
./postgrinstall.sh <ip-address1>,<ip-address2>
```
Вместо `<ip-address1>,<ip-address2>` напишите необходимые вам ip-адреса или доменные имена машин. Например:
```
./postgrinstall.sh 172.16.0.10,172.16.0.12
```
Или так:
```
./postgrinstall.sh deb.pipohomelab.com,alma.pipohomelab.com
```
<br>
Для примера выполнения команды без ошибок можете просмотреть папку `screenshots` в данном репозитории, храняющую в себе скриншоты с образацми запуска программы.
<br>

## Возникшие трудности

* Первой из трудностей было незнание Ansible. После получения задания его пришлось изучать, однако инструмент оказался несложным, с хорошей документацией и был быстро освоен.

* Далее, возникли проблемы с "родными" пакетами дистрибутивов. Каждый дистрибутив (AlmaLinux, Debian) в своих репозиториях имел странно переделанную (Debian) или не предпочитаемую на официальном сайте PostgreSQL (AlmaLinux) версию. Сперва, для упрощения, была предпринята попытка работать именно с этими пакетами, что отняло много времени и не дало никаких результатов из-за расхождений с документацией.<br>
В итоге было решено использовать пакеты из официальных репозиториев PostgreSQL, которые соответствовали документации проекта, и с которыми оказалось проще работать.

* Ещё одной возникшей трудностью было переключение пользователя и запуск команд для базы данных через `psql`. А именно, передача утилите пароля создаваемого по умолчанию пользователя postgres. Были попытки выполнить это через `su`, передавать пароль через переменные среды и команду `echo`, но безуспешно.<br>
В результате изучения документации к утилите и переменным окружения, был обнаружен ещё один способ передачи пароля, который сработал и используется в программе, через файл паролей `.pgpass`.

* Также хочется отметить интересную формулировку задания. В требованиях указано, что необходимо использовать bash, ansible, python. Само же задание можно решить, пользуясь только bash и ansible или только python и ansible. Однако, чтобы не рисковать и точно пройти по критериям задания (а также продемонстрировать навыки), были использованы все три инструмента. Помимо этого, сказано, что "БД должна отвечать на sql-запросы с внешних ip-адресов". Сначала это задание было истолковано, как "БД должна принимать любые соединения", однако в таком случае это противоречило следующему заданию с пользователем student. Поэтому, было решено оставить только прослушивание со всех адресов, а строчку, которая разрешает любые подключения не прописывать в файл, но оставить комментарием с скрипте на всякий случай.

  ## Послесловие

Это далеко не идеальный вариант программы, в нём есть множество недочётов, такие как пароль 12345678 в открытом виде (очень-очень плохая практика, реализованная здесь исключительно в целях демонстрации), повторяющиеся элементы кода, которые можно было бы заменить на переменные, и тому подобное. Однако, данная программа полностью выполняет указанные в задании требования.<br>
Само же задание вышло интересным, и в процессе выполнения автор научился многому, за что благодарен тем, кто задание составил.
