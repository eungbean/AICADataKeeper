1. README 최상단에
참고용으로만 활용해주세요.
보안이나 시스템 꼬임? 은 책임지지 않습니다.

2. ⚠️  개인키 복사 필수 Step은 text로 유지해 (복붙가능)

3. 초기 설정에서 admin 설정을 전부 제거하고, 
메인 화면에서 admin 지정? 같은걸 추가하면 어떨까? 


지금 cache가 NFS에 있기때문에 문제가 발생하고 있어. 현재 프로젝트에서 아키텍처 변경이 필요해. home folder (/users/{user}) 폴더는 ssh에 유지하고, /users/{user}/data 하위를 /data/users/{user}로 연결시켜. 한가지, /data/users/{user}/dotfile 에 필수로 유지해야하는 dotfile들은 심볼릭링크로 하자. 계획을 짜고 아키텍처 전략을 수립해.

