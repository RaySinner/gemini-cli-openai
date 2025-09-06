# План реализации: Конфигурация Docker через переменные окружения

**Версия:** 1.0
**Статус:** Выполнено

## 1. Цель

Обеспечить запуск Docker-контейнера `gemini-openai-worker` с конфигурацией исключительно через переменные окружения, переданные в команде `docker run`, с фолбэком на `.dev.vars` для непереданных параметров.

## 2. План работ

*   **[TASK-CONFIG-DOCKER-01] Обновить типы окружения:** **Выполнено**
    *   **Файл:** `src/types.ts`
    *   **Изменения:**
        *   Сделать поле `GCP_SERVICE_ACCOUNT` в интерфейсе `Env` опциональным (`?`).
        *   Добавить в интерфейс `Env` новые опциональные поля для каждого компонента OAuth2 кредов:
            *   `GCP_ACCESS_TOKEN?: string;`
            *   `GCP_REFRESH_TOKEN?: string;`
            *   `GCP_SCOPE?: string;`
            *   `GCP_TOKEN_TYPE?: string;`
            *   `GCP_ID_TOKEN?: string;`
            *   `GCP_EXPIRY_DATE?: string;`

*   **[TASK-CONFIG-DOCKER-02] Реализовать логику чтения переменных:** **Выполнено**
    *   **Файл:** `src/auth.ts`
    *   **Изменения:**
        *   В классе `AuthManager`, создать новый приватный метод `getOAuth2Credentials(): OAuth2Credentials`.
        *   Этот метод должен сначала проверять наличие `this.env.GCP_REFRESH_TOKEN`.
        *   Если `GCP_REFRESH_TOKEN` и другие `GCP_*` переменные присутствуют, он должен собрать из них объект `OAuth2Credentials`. `GCP_EXPIRY_DATE` нужно будет преобразовать в число.
        *   Если `GCP_REFRESH_TOKEN` отсутствует, метод должен попытаться распарсить `this.env.GCP_SERVICE_ACCOUNT`.
        *   Если оба способа не увенчались успехом, метод должен выбрасывать ошибку.
        *   В методе `initializeAuth`, заменить прямое обращение к `this.env.GCP_SERVICE_ACCOUNT` на вызов нового метода `getOAuth2Credentials()`.

*   **[TASK-CONFIG-DOCKER-03] Обновить документацию:** **Выполнено**
    *   **Файл:** `README.md`
    *   **Изменения:**
        *   Добавить новый раздел "Docker Run with Environment Variables (PowerShell)".
        *   В этом разделе предоставить готовый к копированию, рабочий пример команды `docker run` для PowerShell, демонстрирующий передачу всех необходимых `GCP_*` переменных через аргументы `-e`. Особое внимание уделить правильному экранированию символов для PowerShell.