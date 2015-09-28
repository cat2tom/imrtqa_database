CREATE TABLE delta4 (
uid varchar(255) primary key,
mobiusuid varchar(255),
tomouid varchar(255),
linacuid varchar(255),
id varchar(16), 
name varchar(255),
clinic text,
plan varchar(255),
plandate float,
planuser varchar(255), 
measdate float,
measuser varchar(255),
reviewstatus varchar(16), 
reviewdate float,
reviewuser varchar(255),
comments text,
phantom varchar(16),
students varchar(255),
cumulativemu float,
expectedmu float,
machine varchar(16),
machinetype varchar(16),
temperature float,
reference varchar(255),
normdose float,
abs float,
dta float,
abspassrate float,
dtapassrate float,
gammapassrate float,
dosedev float,
report blob);

CREATE TABLE tomo (
uid varchar(255) primary key,
id varchar(255),
name varchar(255),
plan varchar(255),
plandate float,
machine varchar(16),
gantrymode varchar(16),
jawmode varchar(16),
rxdose float,
fractions float,
doseperfx float,
pitch float,
fieldwidth float,
period float,
numprojections float,
projtime float,
txtime float,
couchspeed float,
couchlength float,
planmod float,
optimod float,
actualmod float,
sinogram blob,
rtplan blob);

CREATE TABLE linac (
uid varchar(255) primary key,
id varchar(255),
name varchar(255),
plan varchar(255),
plandate float,
machine varchar(16),
tps varchar(16),
mode varchar(16),
rxdose float,
fractions float,
doseperfx float,
numbeams int,
numcps int,
rtplan blob);

CREATE TABLE mobius (
uid varchar(255) primary key,
id varchar(255),
name varchar(255),
plan varchar(255),
plandate float,
abs float,
dta float,
gammapassrate float,
version varchar(16),
plancheck blob);

CREATE TABLE scannedfiles (
fullfile text primary key
);

.save database.db