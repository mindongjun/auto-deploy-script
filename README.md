# Auto Deploy Script

Shell Script for AWS Deploy. Written By @capollux.

## 1. AWS EC2 생성

**Ubuntu 16.04 LTS**로 EC2 Instance를 생성한다. 본 스크립트는 해당 OS를 바탕으로 작성되었다.

## 2. Project 설정 (Client)

### 2.1. Gemfile

**Gemfile**에 `figaro`, `mysql2` gem을 추가한다. 단, `mysql2` gem은 production에서만 사용할 것이기 때문에 아래와 같이 production group안에 넣어준다.

```ruby
gem 'figaro'

group :production do
  gem 'mysql2'
end
``` 

Gemfile 작성 완료 후, terminal에서 `--without production` 옵션과 함께 `bundle install`을 해준다. 위에서 설정한 production group안의 gem들을 설치하지 않기 위해서이다.

```console
$ bundle install --without production
```

### 2.2. database.yml

**config/database.yml**의 production 부분을 아래와 같이 작성한다. 여기서 [MY-APP-NAME]은 본인의 Project 이름으로 바꿔 넣으면 된다.

```yaml
production:
  adapter: mysql2
  host: 127.0.0.1
  database: [MY-APP-NAME]_production
  username: root
  password: <%= ENV.fetch("DATABASE_PASSWORD"){ "" } %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

### 2.3. figaro

**config/application.yml**을 생성하고, .gitignore에 해당 파일이 추가되도록 아래의 명령어를 입력한다.

```console
$ bundle exec figaro install
```

### 2.4. git push

변경 사항을 commit 하고, push 해준다.

```console
$ git add -A
$ git commit -m "For auto deploy script"
$ git push
```

## 3. EC2 설정 (Server)

### 3.1. Github에서 Project 가져오기

`git clone` 명령어로 본인의 project를 가져온다. 여기서 **GITHUB-URL-HTTPS**는 github repository의 **Clone whth HTTPS**에서 확인 가능한 URL이다.

```console
$ git clone [GITHUB-URL-HTTPS]
```

### 3.2. Auto Deploy Script 가져오기

git clone` 명령어로 **Auto Deploy Script**를 가져온다. 지금 보고 있는 이 문서의 repository이다.

```console
$ git clone https://github.com/likelion-campus/auto-deploy-script.git
```

### 3.3. Auto Deploy Script 실행하기


#### 3.3.1. Script 실행 권한

Rails application deploy를 매우 편리하게 해주기 위하여 script를 작성하였다. 아까 받은 Auto Deploy Script를 실행하면 모든 설정이 자동으로 될 것이다. 지금은 단순한 text 파일인데, 이 파일을 실행 가능한 script 파일로 바꿔주기 위하여 해당 파일에 실행 권한을 부여하자.

```console
$ sudo chmod u+x auto-deploy-script/*.sh
```

#### 3.3.2. 1.sh 실행

실행 권한이 부여되면 실행을 해보자. 우선 `1.sh` 먼저.

```console
$ ./auto-deploy-script/1.sh
```

실행을 하고 기다리다보면 mysql 암호를 설정하는 창이 나온다. 원하는 암호를 입력하고 넘어가자. 이 암호는 추후에 필요하므로 기억할 것!

#### 3.3.3. shell 새로고침

`1.sh`에서 많은 것들을 설치하였는데, 그것들을 사용하기 위하여 shell을 refresh 해주자. 가끔 프로그램을 설치하고 컴퓨터를 재부팅 해주는 것과 같은 이유이다.

```console
$ exec $SHELL
```

#### 3.3.4. 2.sh 실행

shell도 refresh 했겠다 `2.sh`를 실행하여 나머지 부분의 설정을 계속하자.
`2.sh`에는 몇가지 parameter를 함께 넣어주어야 하는데 **PROJECT-FOLDER-NAME**은 *3.1.*에서 `git clone`하였을때, 받아지는 github repository의 이름이다. `ls` 명령어로 확인이 가능하다.
**DATABASE-PASSWORD**는 *3.3.2*에서 설정한 mysql 암호를 넣어준다.

```console
$ ./auto-deploy-script/2.sh [PROJECT-FOLDER-NAME] [DATABASE-PASSWORD]
```

시간이 조금 걸리는데, 모든 과정을 마치면 브라우저에서 EC2의 Public IP로 접속을 하여 Application이 돌아가는 것을 확인 할 수 있다.



