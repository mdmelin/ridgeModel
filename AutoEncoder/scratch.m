clc;clear all;close all

cPath = 'X:/Widefield'; % change this to server path
Animal = 'mSM66';
Rec = '16-Jul-2018';


[autoenc,msError,R] = wfieldAutoencoder(cPath,Animal,Rec,[5 6],100,true);

