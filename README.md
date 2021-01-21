# env

## 環境需求
1. docker server engine
2. mac os 
3. curl
4. bash
5. shell


## 使用方式

使用具有 `sudo` 權限的使用者執行 hack/install-kind.sh 的腳本

腳本會自動安裝 kubernetes 以及開發會用到的相關環境(1 controller plane node , 2 worker node )

-  mysql
    - user
        - password: mysql
        - username: root
    - port
        - 30036
- redis
    - user
        - password: redis
        - username: default
    - port
        - 30000

- nats
    - client 
        - port
            - 30422
    - cluster
        - port
            - 30222