# Play a queue of uris. Returns a function to push new uris in the queue as well as the resulting source.
# @category Source / Track Processing
# @param ~id Force the value of the source ID.
# @param ~conservative If true, estimated remaining time on the current track is not considered when computing queue length.
# @param ~default_duration When unknown, assume this duration (in sec.) for files.
# @param ~interactive Should the queue be controllable via telnet?
# @param ~length How much audio (in sec.) should be queued in advance.
# @param ~queue Initial queue of requests.
# @param ~timeout Timeout (in sec.) for a single download.
def request.queue.pushable(~id="", ~conservative=false, ~default_duration=30., ~interactive=true, ~length=40., ~queue=[], ~timeout=20.)
  queue = ref(queue)
  def next()
    r = list.hd(default=request.create(""), !queue)
    queue := list.tl(!queue)
    log.info(label=id, "Next song will be #{request.uri(r)}.")
    r
  end
  def push(uri)
    log.info(label=id, "Pushing #{uri} on the queue.")
    queue := list.append(!queue, [uri])
  end
  s = request.dynamic(id=id, conservative=conservative, default_duration=default_duration, length=length, timeout=timeout, available={not list.is_empty(!queue)}, next)
  if interactive then
    namespace = if id == "" then "queue" else id end
    def push(uri) =
      r = request.create(uri)
      push(r)
      "#{request.id(r)}"
    end
    server.register(namespace=namespace, description="Push a new request in the queue.", usage="push <uri>", "push", push)
    def show_queue(_) =
      string.concat(separator=" ", list.map(fun (r) -> string_of(request.id(r)), !queue))
    end
    server.register(namespace=namespace, description="Display current queue content.", usage="queue", "queue", show_queue)
    def skip(_) = source.skip(s); "Done." end
    server.register(namespace=namespace, description="Skip current song.", usage="skip", "skip", skip)
  end
  (push, s)
end

# Play a queue of uris. This function is mainly meant to be controlled over telnet.
# @category Source / Track Processing
# @param ~id Force the value of the source ID.
# @param ~conservative If true, estimated remaining time on the current track is not considered when computing queue length.
# @param ~default_duration When unknown, assume this duration (in sec.) for files.
# @param ~interactive Should the queue be controllable via telnet?
# @param ~length How much audio (in sec.) should be queued in advance.
# @param ~queue Initial queue of requests.
# @param ~timeout Timeout (in sec.) for a single download.
def request.queue(~id="", ~conservative=false, ~default_duration=30., ~interactive=true, ~length=40., ~queue=[], ~timeout=20.)
  snd(request.queue.pushable(id=id, conservative=conservative, default_duration=default_duration, interactive=interactive, length=length, queue=queue, timeout=timeout))
end
