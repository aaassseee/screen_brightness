/*
 * Copyright (C) 2009 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import kotlin.math.ln

/**
 * A class that contains utility methods related to numbers.
 *
 * @hide Pending API council approval
 */
object MathUtils {

    fun constrain(amount: Int, low: Int, high: Int): Int {
        return if (amount < low) low else (if (amount > high) high else amount)
    }

    fun constrain(amount: Long, low: Long, high: Long): Long {
        return if (amount < low) low else (if (amount > high) high else amount)
    }

    fun constrain(amount: Float, low: Float, high: Float): Float {
        return if (amount < low) low else (if (amount > high) high else amount)
    }

    fun log(a: Float): Float {
        return ln(a.toDouble()).toFloat()
    }

    fun exp(a: Float): Float {
        return kotlin.math.exp(a.toDouble()).toFloat()
    }

    fun sqrt(a: Float): Float {
        return kotlin.math.sqrt(a.toDouble()).toFloat()
    }

    fun sq(v: Float): Float {
        return v * v
    }

    fun lerp(start: Float, stop: Float, amount: Float): Float {
        return start + (stop - start) * amount
    }

    fun norm(start: Float, stop: Float, value: Float): Float {
        return (value - start) / (stop - start)
    }
}