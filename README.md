# Spring PetClinic 샘플 애플리케이션

Spring PetClinic은 Spring Boot 기반의 샘플 웹 애플리케이션입니다. 반려동물 병원을 예시 도메인으로 사용해 보호자, 반려동물, 수의사, 방문 예약 같은 기능을 구현합니다.

이 저장소는 Spring PetClinic 프로젝트를 기반으로 CI/CD 실습과 배포 구성을 함께 확인할 수 있도록 정리한 저장소입니다.

## 주요 기술

- Java 17 이상
- Spring Boot
- Maven 또는 Gradle
- Thymeleaf
- H2, MySQL, PostgreSQL
- Docker, Docker Compose

## 로컬에서 실행하기

먼저 프로젝트를 내려받습니다.

```bash
git clone https://github.com/nicesh0571/real-coding_CI_CD.git
cd real-coding_CI_CD
```

Maven을 사용하는 경우:

```bash
./mvnw spring-boot:run
```

Windows PowerShell에서는 다음 명령어를 사용할 수 있습니다.

```powershell
.\mvnw.cmd spring-boot:run
```

Gradle을 사용하는 경우:

```bash
./gradlew bootRun
```

실행 후 브라우저에서 다음 주소로 접속합니다.

<http://localhost:8080/>

<img width="1042" alt="petclinic-screenshot" src="https://cloud.githubusercontent.com/assets/838318/19727082/2aee6d6c-9b8e-11e6-81fe-e889a5ddfded.png">

## 컨테이너 이미지 만들기

이 프로젝트에는 `Dockerfile`이 포함되어 있어 Docker 이미지로 애플리케이션을 실행할 수 있습니다.

```bash
docker build -t spring-petclinic:latest .
docker run -p 8080:8080 spring-petclinic:latest
```

Spring Boot 빌드 플러그인을 사용해 컨테이너 이미지를 만들 수도 있습니다.

```bash
./mvnw spring-boot:build-image
docker images | grep petclinic
docker run -p 8080:8080 docker.io/library/spring-petclinic:latest
```

Windows PowerShell에서는 다음처럼 실행할 수 있습니다.

```powershell
.\mvnw.cmd spring-boot:build-image
docker images
docker run -p 8080:8080 docker.io/library/spring-petclinic:latest
```

## GitHub Actions CI/CD

이 저장소는 GitHub Actions와 self-hosted runner를 사용해 CI/CD를 구성했습니다. 워크플로 파일은 `.github/workflows/ci.yml`에 있습니다.

동작 흐름은 다음과 같습니다.

1. `main` 브랜치에 push합니다.
2. GitHub Actions가 Maven 빌드를 실행합니다.
3. 빌드가 성공하면 self-hosted runner에서 Docker 이미지를 빌드합니다.
4. 기존 `spring-petclinic` 컨테이너를 제거합니다.
5. 새 컨테이너를 `8080` 포트로 실행합니다.

현재 배포 job은 GitHub가 제공하는 기본 runner가 아니라 직접 등록한 self-hosted runner에서 실행됩니다.

```yaml
runs-on: self-hosted
```

GitHub 기본 runner는 작업이 끝나면 사라지는 임시 환경이기 때문에, 컨테이너를 계속 실행하는 배포 용도로는 적합하지 않습니다. 그래서 Docker가 설치된 내 PC나 서버를 self-hosted runner로 등록해 배포 대상처럼 사용합니다.

### self-hosted runner 등록 방법

GitHub 저장소에서 다음 메뉴로 이동합니다.

```text
Settings -> Actions -> Runners -> New self-hosted runner
```

운영체제를 선택하면 GitHub가 runner 다운로드, 압축 해제, 등록 명령어를 보여줍니다. Windows 기준으로는 대략 다음 순서입니다.

```powershell
mkdir actions-runner
cd actions-runner

Invoke-WebRequest -Uri <GitHub에서 제공하는 runner 다운로드 URL> -OutFile actions-runner-win-x64.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64.zip", "$PWD")

.\config.cmd --url https://github.com/nicesh0571/real-coding_CI_CD --token <GitHub에서 제공하는 등록 토큰>
.\run.cmd
```

`.\run.cmd`를 실행하면 runner가 GitHub와 연결되고 job을 기다립니다. 이 터미널이 켜져 있어야 다음 push 때도 자동 배포가 실행됩니다.

### 배포 결과 확인

배포가 성공하면 runner가 실행 중인 PC 또는 서버에서 다음 주소로 접속할 수 있습니다.

```text
http://localhost:8080
```

만약 self-hosted runner를 클라우드 서버에 설치했다면 `localhost` 대신 서버의 공인 IP 또는 도메인으로 접속합니다.

```text
http://서버IP:8080
```

### 주의사항

- `actions-runner/` 폴더는 GitHub에 올리지 않습니다.
- runner 등록 토큰, `.env`, 개인 키, 비밀번호 파일은 커밋하지 않습니다.
- public 저장소에서 self-hosted runner를 사용할 때는 신뢰할 수 없는 Pull Request가 runner에서 실행되지 않도록 주의해야 합니다.
- runner가 실행되는 PC 또는 서버에는 Docker가 설치되어 있어야 합니다.

## 데이터베이스 설정

기본 설정에서는 H2 인메모리 데이터베이스를 사용합니다. 애플리케이션이 시작될 때 샘플 데이터가 자동으로 입력됩니다.

H2 콘솔은 다음 주소에서 확인할 수 있습니다.

<http://localhost:8080/h2-console>

콘솔 접속 시 사용하는 JDBC URL은 애플리케이션 시작 로그에 출력되는 `jdbc:h2:mem:<uuid>` 값을 확인하면 됩니다.

## MySQL 또는 PostgreSQL 사용하기

영구 데이터베이스가 필요한 경우 MySQL 또는 PostgreSQL 프로필을 사용할 수 있습니다.

- MySQL: `spring.profiles.active=mysql`
- PostgreSQL: `spring.profiles.active=postgres`

Docker로 MySQL을 실행하는 예시:

```bash
docker run -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:9.6
```

Docker로 PostgreSQL을 실행하는 예시:

```bash
docker run -e POSTGRES_USER=petclinic -e POSTGRES_PASSWORD=petclinic -e POSTGRES_DB=petclinic -p 5432:5432 postgres:18.3
```

`docker-compose.yml`을 사용하면 더 간단하게 실행할 수 있습니다.

```bash
docker compose up mysql
```

또는:

```bash
docker compose up postgres
```

## 테스트 애플리케이션

개발 중에는 다음 테스트 애플리케이션을 IDE에서 직접 실행할 수 있습니다.

- `PetClinicIntegrationTests`
- `MySqlTestApplication`
- `PostgresIntegrationTests`

MySQL 통합 테스트는 Testcontainers를 사용해 Docker 컨테이너 안에서 데이터베이스를 실행합니다. PostgreSQL 테스트는 Docker Compose를 사용합니다.

## CSS 컴파일

`src/main/resources/static/resources/css` 경로의 `petclinic.css`는 `petclinic.scss`와 Bootstrap을 기반으로 생성된 파일입니다.

SCSS를 수정하거나 Bootstrap 버전을 변경했다면 다음 명령어로 CSS 리소스를 다시 생성합니다.

```bash
./mvnw package -P css
```

Windows PowerShell:

```powershell
.\mvnw.cmd package -P css
```

Gradle에는 CSS 컴파일용 빌드 프로필이 따로 없습니다.

## IDE에서 실행하기

### 필요한 도구

- Java 17 이상 JDK
- [Git](https://help.github.com/articles/set-up-git)
- 원하는 IDE
  - [IntelliJ IDEA](https://www.jetbrains.com/idea/)
  - [VS Code](https://code.visualstudio.com)
  - [Spring Tools Suite](https://spring.io/tools)
  - Eclipse + m2e 플러그인

### IntelliJ IDEA

1. `File -> Open`을 선택합니다.
2. 프로젝트의 `pom.xml`을 선택합니다.
3. Maven 프로젝트로 import합니다.
4. `PetClinicApplication` 클래스를 실행합니다.
5. 브라우저에서 <http://localhost:8080>에 접속합니다.

### VS Code

1. 프로젝트 폴더를 엽니다.
2. Java와 Spring Boot 관련 확장을 설치합니다.
3. `PetClinicApplication`을 실행합니다.
4. 브라우저에서 <http://localhost:8080>에 접속합니다.

### Eclipse 또는 STS

1. `File -> Import -> Maven -> Existing Maven project`를 선택합니다.
2. clone 받은 저장소의 루트 폴더를 선택합니다.
3. `./mvnw generate-resources`를 실행하거나 IDE의 Maven install 기능으로 리소스를 생성합니다.
4. `PetClinicApplication`을 Java Application으로 실행합니다.

## 주요 위치

| 항목 | 위치 |
|---|---|
| 메인 클래스 | `src/main/java/org/springframework/samples/petclinic/PetClinicApplication.java` |
| 설정 파일 | `src/main/resources/application.properties` |
| 정적 리소스 | `src/main/resources/static` |
| Thymeleaf 템플릿 | `src/main/resources/templates` |
| 테스트 코드 | `src/test/java` |
| Docker Compose 설정 | `docker-compose.yml` |
| Kubernetes 설정 | `k8s` |

## 원본 프로젝트

이 프로젝트는 Spring 공식 샘플인 [spring-projects/spring-petclinic](https://github.com/spring-projects/spring-petclinic)을 기반으로 합니다.

Spring PetClinic의 다양한 구현체와 fork는 [Spring PetClinic 문서](https://spring-petclinic.github.io/docs/forks.html)에서 확인할 수 있습니다.

## 라이선스

Spring PetClinic 샘플 애플리케이션은 [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)에 따라 배포됩니다.
