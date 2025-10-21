# 경복대학교 프로젝트

## 1. 프로젝트 개요

본 프로젝트는 IoT 센서와 모바일 애플리케이션을 연동하여, 원격으로 환자의 상태를 실시간 모니터링하는 시스템입니다.

현재 구현된 기능은 관리자가 Flutter 기반의 모바일 앱을 통해 담당 환자들의 목록과 최신 상태(낙상, 호출 등)를 확인할 수 있는 실시간 모니터링 대시보드입니다. 관리자용 페이지에서는 시스템 사용자의 역할을 관리하는 기능이 구현되어 있습니다.

## 2. 주요 기능

실시간 모니터링 대시보드: Flutter 앱을 통해 각 환자의 최신 상태(낙상, 호출)를 실시간으로 확인.

자동 새로고침 및 알림: 10초마다 데이터를 자동 갱신하고, 새로운 이벤트 발생 시 화면 내 팝업 알림 표시.

비접촉식 낙상 감지: 천장에 설치된 LiDAR 및 초음파 센서의 거리 데이터를 분석하여 낙상 판단.

관리자 기능: 앱을 통해 시스템 사용자(직원, 관리자)의 역할을 관리.

## 3. 시스템 아키텍처

- Edge (환자 환경): 라즈베리파이가 아두이노에 연결된 LiDAR/초음파 센서 데이터를 분석하여 낙상을 판단하고, 결과를 클라우드로 전송합니다.

- Cloud (서버): FastAPI(Python) 기반의 API 서버가 이벤트를 수신하여 MySQL 데이터베이스에 저장합니다.

- Client (관리자): Flutter 모바일 앱이 API 서버와 통신하여 실시간으로 환자 상태를 모니터링합니다.

## 4. 기술 스택

- Frontend (Client): Flutter, Dart

- Backend (Cloud): Python, FastAPI, SQLAlchemy

- Edge Computing: Raspberry Pi 4, Python, Arduino

- Database: MySQL

- Infrastructure: Gabia Cloud, Nginx, Uvicorn

- Sensors: TF Luna LiDAR, Ultrasonic Sensor (HC-SR04)

## 5. 프로젝트 현황 (2학기 진행)

[완료] 클라우드 서버 및 데이터베이스 구축 (FastAPI, MySQL)

[완료] Flutter 모바일 앱 UI 및 핵심 기능 구현 (실시간 모니터링, 알림)

[진행중] 라즈베리파이 기반 낙상 판단 기능 개발 및 테스트

[향후 계획] 센서 융합(LiDAR+초음파) 및 머신러닝(TensorFlow Lite) 모델 도입을 통한 정확도 향상
