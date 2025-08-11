To Join Live as a Broadcaster,

                      Get.to(
                        () => LiveStreamScreen(
                          token:'',
                          channelName:'' ,
                        ),
                      );

To Join Live as a Audience,

                      Get.to(
                        () => LiveWatchScreen(
                          token: '',
                          channelName: '',
                        ),
                        arguments: 'Live Title',
                      );
