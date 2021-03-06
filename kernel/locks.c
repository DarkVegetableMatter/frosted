/*  
 *      This file is part of frosted.
 *
 *      frosted is free software: you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License version 2, as 
 *      published by the Free Software Foundation.
 *      
 *
 *      frosted is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with frosted.  If not, see <http://www.gnu.org/licenses/>.
 *
 *      Authors: Daniele Lacamera, Maxime Vincent
 *
 */  
#include "frosted.h"

/* Structures */
struct semaphore {
    int value;
    int listeners;
    int *listener;
};

typedef struct semaphore sem_t;
typedef struct semaphore mutex_t;

/* Semaphore: internal functions */
static void _add_listener(sem_t *s)
{
    int i;
    int pid = scheduler_get_cur_pid();
    for (i = 0; i < s->listeners; i++) {
        if (s->listener[i] == pid)
            return;
    }
    s->listener = krealloc(s->listener, sizeof(int) * (s->listeners + 1));
    if (!s->listener)
        return;
    s->listener[s->listeners++] = pid;
}

static void _del_listener(sem_t *s)
{
    int i;
    int pid = scheduler_get_cur_pid();
    for (i = 0; i < s->listeners; i++) {
        if (s->listener[i] == pid) {
            s->listener[i] = -1;
            return;
        }
    }
}

/* Semaphore: API */
int sem_wait(sem_t *s)
{
    if (!s)
        return -1;
    if(_sem_wait(s) != 0) {
        _add_listener(s);
        task_suspend();
        return SYS_CALL_AGAIN;
    }
    _del_listener(s);
    return 0;
}

int sem_post(sem_t *s)
{
    if (!s)
        return -1;
    if (_sem_post(s) > 0) {
        int i;
        for(i = 0; i < s->listeners; i++) {
            int pid = s->listener[i];
            if (pid >= 0) {
                task_resume(pid);
            }
        }
    }
    return 0;
}

int sem_destroy(sem_t *sem)
{
    if (sem->listener)
        kfree(sem->listener);
    kfree(sem);
    return 0;
}

sem_t *sem_init(int val)
{
    sem_t *s = kalloc(sizeof(sem_t));
    if (s) {
        s->value = val;
        s->listeners = 0;
        s->listener = NULL;
    }
    return s;
}

/* Semaphore: Syscalls */
int sys_sem_init_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return (int)sem_init(arg1);
}

int sys_sem_post_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return sem_post((sem_t *)arg1);
}

int sys_sem_wait_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return sem_wait((sem_t *)arg1);
}

int sys_sem_destroy_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return sem_destroy((sem_t *)arg1);
}

/* Mutex: API */
mutex_t *mutex_init()
{
    mutex_t *s = kalloc(sizeof(mutex_t));
    if (s) {
        s->value = 1; /* Unlocked. */
        s->listeners = 0;
        s->listener = NULL;
    }
    return s;
}

int mutex_lock(mutex_t *s)
{
    if (!s)
        return -1;
    if(_mutex_lock(s) != 0) {
        _add_listener(s);
        task_suspend();
        return SYS_CALL_AGAIN;
    }
    _del_listener(s);
    return 0;
}

int mutex_unlock(mutex_t *s)
{
    if (!s)
        return -1;
    if (_mutex_unlock(s) == 0) {
        int i;
        for(i = 0; i < s->listeners; i++) {
            int pid = s->listener[i];
            if (pid >= 0) {
                task_resume(pid);
            }
        }
        return 0;
    }
    return -1;
}

/* Mutex: Syscalls */
int sys_mutex_init_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return (int)mutex_init(arg1);
}

int sys_mutex_lock_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return mutex_lock((mutex_t *)arg1);
}

int sys_mutex_unlock_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return mutex_unlock((mutex_t *)arg1);
}

int sys_mutex_destroy_hdlr(int arg1, int arg2, int arg3, int arg4, int arg5)
{
    return sem_destroy((sem_t *)arg1); /* Same as semaphore */
}

