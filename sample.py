import tensorflow as tf
import random
import model

def top_k_logits(logits, k):
    if k == 0:
        # no truncation
        return logits

    def _top_k():
        values, _ = tf.nn.top_k(logits, k=k)
        min_values = values[:, -1, tf.newaxis]
        return tf.where(
            logits < min_values,
            tf.ones_like(logits, dtype=logits.dtype) * -1e10,
            logits,
        )
    return tf.cond(
       tf.equal(k, 0),
       lambda: logits,
       lambda: _top_k(),
    )

def top_p_logits(logits, p):
    with tf.variable_scope('top_p_logits'):
        logits_sort = tf.sort(logits, direction='DESCENDING')

        # logits_sort = (logits_sort[i,:] for i in range(logits_sort.get_shape().as_list()[0]))
        probs_sort = tf.nn.softmax(logits_sort)
        probs_sums = tf.cumsum(probs_sort, axis=1, exclusive=True)

        logits_masked = tf.where(probs_sums < p, logits_sort, tf.ones_like(logits_sort)*1000) # [batchsize, vocab]
        min_logits = tf.reduce_min(logits_masked, axis=1, keepdims=True) # [batchsize, 1]
        return tf.where(
            logits < min_logits,
            tf.ones_like(logits, dtype=logits.dtype) * -1e10,
            logits,
        )

# length=8, batch_size=5,
def sample_sequence(*, hparams, length, start_token=None, batch_size=None, context=None, temperature=0, top_k=0, top_p=0):
    if start_token is None:
        assert context is not None, 'Specify exactly one of start_token and context!'
    else:
        assert context is None, 'Specify exactly one of start_token and context!'
        context = tf.fill([batch_size, 1], start_token)

    def step(hparams, tokens, past=None):
        lm_output = model.model(hparams=hparams, X=tokens, past=past, reuse=tf.AUTO_REUSE)

        logits = lm_output['logits'][:, :, :hparams.n_vocab]
        presents = lm_output['present']
        presents.set_shape(model.past_shape(hparams=hparams, batch_size=batch_size))
        return {
            'logits': logits,
            'presents': presents,
        }

    with tf.name_scope('sample_sequence'):
        def body(past, prev, output):
            next_outputs = step(hparams, prev, past=past)
            # print(tf.unstack(next_outputs['logits'][:, -1, :] ))

            if temperature == 0:
                logits = tf.map_fn(fn=lambda logit_tensor: logit_tensor / tf.random.uniform((1,), minval=.69, maxval=.91, dtype=tf.dtypes.float32),
                    elems=next_outputs['logits'][:, -1, :],
                    back_prop=False,
                    dtype=tf.float32)
            else:
                logits = next_outputs['logits'][:, -1, :]  / tf.to_float(temperature)

            # logits = top_p_logits(logits, p=top_p)
            if top_p:
                logits = top_p_logits(logits, p=top_p)
            else:
                logits = top_k_logits(logits, k=top_k)
            samples = tf.multinomial(logits, num_samples=1, output_dtype=tf.int32)

            # samples = tf.math.top_k( logits, k=1 ).indices

            return [
                next_outputs['presents'] if past is None else tf.concat([past, next_outputs['presents']], axis=-2),
                samples,
                tf.concat([output, samples], axis=1)
            ]

        past, prev, output = body(None, context, context)

        def cond(*args):
            return True

        _, _, tokens = tf.while_loop(
            cond=cond, body=body,
            maximum_iterations=length - 1,
            loop_vars=[
                past,
                prev,
                output
            ],
            shape_invariants=[
                tf.TensorShape(model.past_shape(hparams=hparams, batch_size=batch_size)),
                tf.TensorShape([batch_size, None]), # 5* ()
                tf.TensorShape([batch_size, None]), # 5* ()
            ],
            back_prop=False,
        )

        return tokens


def get_top(*, hparams, length, start_token=None, batch_size=None, context=None, top_k=0, top_p=0):
    if start_token is None:
        assert context is not None, 'Specify exactly one of start_token and context!'
    else:
        assert context is None, 'Specify exactly one of start_token and context!'
        context = tf.fill([batch_size, 1], start_token)

    def step(hparams, tokens, past=None):
        lm_output = model.model(hparams=hparams, X=tokens, past=past, reuse=tf.AUTO_REUSE)

        logits = lm_output['logits'][:, :, :hparams.n_vocab]
        presents = lm_output['present']
        presents.set_shape(model.past_shape(hparams=hparams, batch_size=batch_size))
        return {
            'logits': logits,
            'presents': presents,
        }

    with tf.name_scope('get_top'):
        num_for_each = 3
        def body(past, prev, output):
            next_outputs = step(hparams, prev, past=past)
            logits = next_outputs['logits'][:, -1, :]  / tf.to_float(1)

            num_for_pick = batch_size // num_for_each +1
            if output == context :
                # 1 * num_for_pick
                top_bs = tf.slice( tf.math.top_k( logits, k=num_for_pick ).indices, [0,0], [1,num_for_pick] )
                out_list = []
                for i in range(batch_size):
                    out_list.append(top_bs[0][i//num_for_each])
                samples = tf.stack([out_list])
                samples = tf.transpose(samples)
                # batch_size * 1
            else:
                samples = tf.math.top_k( logits, k=1 ).indices

            return [
                next_outputs['presents'] if past is None else tf.concat([past, next_outputs['presents']], axis=-2),
                samples,
                tf.concat([output, samples], axis=1),
            ]

        def body2(past, prev, output):
            next_outputs = step(hparams, prev, past=past)
            logits = next_outputs['logits'][:, -1, :]  / tf.to_float(1)

            top_bs = tf.math.top_k( logits, k=num_for_each ).indices
            out_list = []
            for i in range(batch_size):
                out_list.append(top_bs[i][i % num_for_each])
            samples = tf.stack([out_list])
            samples = tf.transpose(samples)
            return [
                next_outputs['presents'] if past is None else tf.concat([past, next_outputs['presents']], axis=-2),
                samples,
                tf.concat([output, samples], axis=1),
            ]

        past, prev, output = body(None, context, context)
        past, prev, output = body2(past, prev, output)

        def cond(*args):
            return True

        _, _, tokens = tf.while_loop(
            cond=cond, body=body,
            maximum_iterations=length - 1,
            loop_vars=[
                past,
                prev,
                output,
            ],
            shape_invariants=[
                tf.TensorShape(model.past_shape(hparams=hparams, batch_size=batch_size)),
                tf.TensorShape([batch_size, None]), # 5* ()
                tf.TensorShape([batch_size, None]), # 5* ()
            ],
            back_prop=False,
        )

        return tokens
