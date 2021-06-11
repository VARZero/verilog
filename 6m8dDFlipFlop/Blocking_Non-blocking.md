# Blocking vs. Non-Blocking
베릴로그에서 값을 지정하는데는 =와 <= 두가지를 사용한다. 왜?

## 먼저 비교해서 보자
### 4-bit shift register를 만든하고 할때

    always @ (posedge clk) begin
        a[3] = in;
        a[2] = a[3];
        a[1] = a[2];
        a[0] = a[1];
    end

위 경우에서는 4개 모두 in의 값이 들어간다..

    always @ (posedge clk) begin
        a[3] <= in;
        a[2] <= a[3];
        a[1] <= a[2];
        a[0] <= a[1];
    end

위 경우에서는 in이 a의 MSB에, 나머지는 한칸 앞으로 shift 된다.

## Blocking
*=* 을 사용하는 경우<br>
LHS는 RHS가 업데이트 된 직후 업데이트 됩니다.<br>
그러니까 절차적 할당(Procerdural Assignments)에서는 실행이 막힌(blocking) 것과 같다고 볼 수 있다.

## Non-Blocking
*<=* 을 사용하는 경우<br>
RHS는 업데이트가 되고, LHS 할당은 오직 예약된다.<br>
모듈이 업데이트 될때만 LHS는 RHS의 값으로 업데이트 됩니다.<br>
그러니까 절차적 할당(Procerdural Assignments)에서는 실행이 막히지 않은(non-blocking) 것과 같다고 볼 수 있다.

## 정리
정리하자면,<br>
*=*는 한줄 씩 절차적으로 실행되고<br>
*<=*는 모듈이 동작할때 같이 실행