//go:build !ignore_autogenerated
// +build !ignore_autogenerated

/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Code generated by controller-gen. DO NOT EDIT.

package v1alpha1

import (
	runtime "k8s.io/apimachinery/pkg/runtime"
)

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ComponentStatus) DeepCopyInto(out *ComponentStatus) {
	*out = *in
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ComponentStatus.
func (in *ComponentStatus) DeepCopy() *ComponentStatus {
	if in == nil {
		return nil
	}
	out := new(ComponentStatus)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ComponentStatusMap) DeepCopyInto(out *ComponentStatusMap) {
	*out = *in
	out.Noobaa = in.Noobaa
	out.Prometheus = in.Prometheus
	out.Alertmanager = in.Alertmanager
	out.Console = in.Console
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ComponentStatusMap.
func (in *ComponentStatusMap) DeepCopy() *ComponentStatusMap {
	if in == nil {
		return nil
	}
	out := new(ComponentStatusMap)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ManagedMCG) DeepCopyInto(out *ManagedMCG) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	out.Spec = in.Spec
	out.Status = in.Status
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ManagedMCG.
func (in *ManagedMCG) DeepCopy() *ManagedMCG {
	if in == nil {
		return nil
	}
	out := new(ManagedMCG)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *ManagedMCG) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ManagedMCGList) DeepCopyInto(out *ManagedMCGList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		in, out := &in.Items, &out.Items
		*out = make([]ManagedMCG, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ManagedMCGList.
func (in *ManagedMCGList) DeepCopy() *ManagedMCGList {
	if in == nil {
		return nil
	}
	out := new(ManagedMCGList)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *ManagedMCGList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ManagedMCGSpec) DeepCopyInto(out *ManagedMCGSpec) {
	*out = *in
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ManagedMCGSpec.
func (in *ManagedMCGSpec) DeepCopy() *ManagedMCGSpec {
	if in == nil {
		return nil
	}
	out := new(ManagedMCGSpec)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *ManagedMCGStatus) DeepCopyInto(out *ManagedMCGStatus) {
	*out = *in
	out.Components = in.Components
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new ManagedMCGStatus.
func (in *ManagedMCGStatus) DeepCopy() *ManagedMCGStatus {
	if in == nil {
		return nil
	}
	out := new(ManagedMCGStatus)
	in.DeepCopyInto(out)
	return out
}
