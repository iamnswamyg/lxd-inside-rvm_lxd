#!/bin/bash

doveadm expunge -A MAILBOX INBOX/* BEFORE 30d
doveadm expunge -u "logmails@ufprod.lan" MAILBOX INBOX/* BEFORE 3d
doveadm expunge -u "noreply@ufprod.lan" MAILBOX INBOX BEFORE 3d
doveadm expunge -u "forward@ufprod.lan" MAILBOX INBOX/* BEFORE 7d
doveadm purge -A
