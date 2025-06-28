package com.web3.vo;

import lombok.Data;
import lombok.ToString;

@Data
@ToString
public class ReturnDataVO<T> {

    private boolean success;
    private String msg;
    private T data;

    public ReturnDataVO(boolean success,String msg,T data){
        this.success = success;
        this.msg = msg;
        this.data = data;
    }

    public static <T> ReturnDataVO<T> success(T data){
        return new ReturnDataVO<T>(true,"",data);
    }

    public static  <T>ReturnDataVO<T> success(){
        return new ReturnDataVO<T>(true,"",null);
    }

    public static <T> ReturnDataVO<T> fail(String msg){
        return new ReturnDataVO<T>(false,msg,null);
    }
}
