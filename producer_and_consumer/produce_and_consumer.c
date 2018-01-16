#include <stdio.h>
#include <pthread.h>
pthread_mutex_t the_mutex;
pthread_cond_t condc, condp;
int buffer = 0;
int consumed = 0; //record of consumed items
/*
The producer-Consumer Problem
using threads and semaphores
buffer size (N) = 10
the number of producers is 3
the number of consumers is 2
terminate condition: the total consumed items is equal to 50
output: print out the behaves of producers and consumers in turn
*/

void *producer(void* p)
{
	int *ptr = (int*)p;
	//when the consumed items is equal to 50, stop producing
	while(consumed <= 50)
	{
		pthread_mutex_lock(&the_mutex);
                //when buffer is not less than 10, producer will begin waiting
		while(buffer >= 10)
		{
			printf("Producer %d begin waiting for consumers, the buffer is %d now.\n", *ptr, buffer);
			pthread_cond_wait(&condp, &the_mutex);
		}
		buffer++;
		printf("Producer %d completed one production, the buffer is %d now.\n", *ptr, buffer);
		pthread_cond_signal(&condc);
		pthread_mutex_unlock(&the_mutex);
	}
	pthread_exit(0);
}

void *consumer(void* p)
{
	int *ptr = (int*)p;
	while(consumed <= 50)
	{
		pthread_mutex_lock(&the_mutex);
		while(buffer == 0)  //when buffer equal to 0, stop consuming and waiting for producters
		{
			printf("Consumer %d begin waiting for producers, the buffer is %d now.\n", *ptr, buffer);
			pthread_cond_wait(&condc, &the_mutex);
		}
		buffer--;
		consumed++;
		printf("Consumer %d completed one consumption, the number of consumed items is %d!\n", *ptr, consumed);
		pthread_cond_signal(&condp);
		pthread_mutex_unlock(&the_mutex);
	}
	pthread_exit(0);
}

int main(int argc, char **argv)
{
	pthread_t pro[3];
	pthread_t con[2];
	int i;
	void *index[5];
	int number[3] = {1,2,3};
	index[0] = index[3] = &number[0];
	index[1] = index[4] = &number[1];
	index[2] = &number[2];
	pthread_mutex_init(&the_mutex, 0);
	pthread_cond_init(&condc, 0);
	pthread_cond_init(&condp, 0);
	pthread_create(&pro[0], 0, producer, index[0]);
	pthread_create(&pro[1], 0, producer, index[1]);
	pthread_create(&pro[2], 0, producer, index[2]);
	pthread_create(&con[0], 0, consumer, index[3]);
	pthread_create(&con[1], 0, consumer, index[4]);
	pthread_join(pro[0], 0);
	pthread_join(pro[1], 0);
	pthread_join(pro[2], 0);
	pthread_join(con[0], 0);
	pthread_join(con[1], 0);
	pthread_cond_destroy(&condc);
	pthread_cond_destroy(&condp);
	pthread_mutex_destroy(&the_mutex);
	return 0;
}
