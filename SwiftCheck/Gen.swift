//
//  Gen.swift
//  SwiftCheck
//
//  Created by Robert Widmann on 7/31/14.
//  Copyright (c) 2014 Robert Widmann. All rights reserved.
//

import Foundation
import Swift_Extras

public struct Gen<A> {
	var unGen: StdGen -> Int -> A
}

extension Gen : Functor {
	typealias B = Any
	public static func fmap<B>(f: (A -> B)) -> Gen<A> -> Gen<B> {
		return { (let g) in
			Gen<B>(unGen: { (let r) in
				return { (let n) in
					return f(g.unGen(r)(n))
				}
			}) 
		}
	}

	public func bind<B>(fn: A -> Gen<B>) -> Gen<B> {
		return Gen<B>(unGen: { (let r) in
			return { (let n) in
				let (r1, r2) = r.split()
				let m = fn(self.unGen(r1)(n))
				return m.unGen(r2)(n)
			}
		})
	}

	public func bindWitness(fn: A -> WitnessTestableGen) -> WitnessTestableGen {
		return WitnessTestableGen(Gen<Prop>(unGen: { (let r) in
			return { (let n) in
				let (r1, r2) = r.split()
				let m = fn(self.unGen(r1)(n))
				return mkGen(m).unGen(r2)(n)
			}
		}))
	}
}

public func <%><A, B>(f: A -> B, ar : Gen<A>) -> Gen<B> {
	return Gen.fmap(f)(ar)
}

public func <^<A, B>(x : A, l : Gen<B>) -> Gen<A> {
	return Gen.fmap(const(x))(l)
}



extension Gen : Applicative {
	public static func pure(a: A) -> Gen<A> {
		return Gen(unGen: { (_) in
			return { (_) in
				return a
			}
		})
	}

	public func ap<B>(fn: Gen<A -> B>) -> Gen<B> {
		return Gen<B>(unGen: { (let r) in
			return { (let n) in
				return fn.unGen(r)(n)(self.unGen(r)(n))
			}
		})
	}
}

public func <*><A, B>(a : Gen<A -> B> , l : Gen<A>) -> Gen<B> {
	return l.ap(a)
}

public func *><A, B>(a : Gen<A>, b : Gen<B>) -> Gen<B> {
	return const(id) <%> a <*> b
}

public func <*<A, B>(a : Gen<A>, b : Gen<B>) -> Gen<A> {
	return const <%> a <*> b
}

public func sequence<A>(ms: [Gen<A>]) -> Gen<[A]> {
	return foldr({ (let x, let y) in
		return x >>= { (let x1) in
			return y >>= { (let xs) in
				return Gen<[A]>.pure([x1] + xs)
			}
		}
	})(z: Gen<[A]>.pure([]))(l: ms)
}

public func >>=<A, B>(x : Gen<A>, f : A -> Gen<B>) -> Gen<B> {
	return x.bind(f)
}

public func >><A, B>(x : Gen<A>, y : Gen<B>) -> Gen<B> {
	return x.bind({ (_) in
		return y
	})
}

public func join<A>(rs: Gen<Gen<A>>) -> Gen<A> {
	return rs >>= { (let x) in
		return x
	}
}

public func liftM<A, R>(f: A -> R)(m1 : Gen<A>) -> Gen<R> {
	return m1 >>= { (let x1) in
		return Gen.pure(f(x1))
	}
}

public func do_<A>(fn: () -> Gen<A>) -> Gen<A> {
	return fn()
}

public func promote<A>(x : Rose<Gen<A>>) -> Gen<Rose<A>> {
	return delay() >>= ({ (let eval : Gen<A> -> A) in
		return Gen<Rose<A>>.pure(liftM(eval)(m1: x))
	})
}


public func delay<A>() -> Gen<Gen<A> -> A> {
	return Gen(unGen: { (let r) in
		return { (let n) in
			return { (let g) in
				return g.unGen(r)(n)
			}
		}
	})
}
