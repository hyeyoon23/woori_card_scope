# 1. 이미지 빌드 (Lombok 컴파일 확인)

docker compose build --no-cache

# 2. 컨테이너 기동

docker compose up -d

# 3. 상태 확인 (nginx ×2, was ×2 모두 running)

docker compose ps

# 4. WAS 직접 접근 테스트

curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8090/

# 5. nginx 경유 접근 테스트

curl -s -o /dev/null -w "%{http_code}\n" [http://localhost:80/](http://localhost/)
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:81/
